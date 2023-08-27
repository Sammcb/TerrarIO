//
//  TerrariaWorldDocument.swift
//  TerrarIO
//
//  Created by Sam McBroom on 8/23/23.
//

import SwiftUI
import UniformTypeIdentifiers

extension UTType {
	static let worldDocument = UTType(exportedAs: "com.sammcb.terrario")
}

struct Rect: Hashable {
	let x: Int
	let y: Int
	let width: Int
	let height: Int
	var cgRect: CGRect {
		CGRect(x: x, y: y, width: width, height: height)
	}
}

class WorldDocument: ReferenceFileDocument {
	typealias MapPaths = [Rect: [Color: Path]]
	
	typealias Snapshot = World
	
	static var readableContentTypes: [UTType] = [.worldDocument]
	
	@Published var world = World()
	@Published var paths: MapPaths = [:]
	@Published var pathsDone = false
	static let pixelScale = 1
	
	init() {}
	
	required init(configuration: ReadConfiguration) throws {
		guard let data = configuration.file.regularFileContents else {
			throw CocoaError(.fileReadCorruptFile)
		}
		
		world = World(data)
		Task {
			let paths = await Self.generatePaths(world: world)
			await MainActor.run {
				self.paths = paths
				self.pathsDone = true
			}
		}
	}
	
	func snapshot(contentType: UTType) throws -> World {
		world
	}
	
	func fileWrapper(snapshot: World, configuration: WriteConfiguration) throws -> FileWrapper {
		let data = snapshot.data
		return FileWrapper(regularFileWithContents: data)
	}
}

extension WorldDocument {
	private static func pathColor(for tile: World.Tiles.Tile) -> Color? {
		if tile.hasTile {
			return .brown
		} else if tile.liquidType != .none {
			return .purple
		} else if tile.hasWall {
			return .gray
		}
		return nil
	}
	
	private class Line {
		typealias Segment = (start: CGPoint, end: CGPoint)
		var segments: [Segment] = []
		var path: Path {
			var path = Path()
			for segment in segments {
				path.addLines([segment.start, segment.end])
			}
			return path
		}
	}
	
	private static func chunkPaths(from world: World, in heightRange: Range<Int>, in widthRange: Range<Int>) -> [Rect: [Color: Line]] {
		let tileColumnsSubset = world.tiles.tiles[widthRange]
		var coloredLines: [Color: Line] = [:]
		
		for (rowIndex, tileColumn) in tileColumnsSubset.enumerated() {
			guard rowIndex % pixelScale == 0 else {
				continue
			}
			
			let tilesSubset = tileColumn[heightRange]
			let xCoordinate = rowIndex + widthRange.lowerBound
			var currentLine: (color: Color?, start: Int) = (nil, 0)
			
			for (columnIndex, tile) in tilesSubset.enumerated() {
				guard columnIndex % pixelScale == 0 else {
					continue
				}
				
				let yCoordnate = columnIndex + heightRange.lowerBound
				
				let color = pathColor(for: tile)
				// 693 possible tiles
				let totalColors = 693
				let initColorV = (xCoordinate + yCoordnate) % totalColors
				let v = Double(initColorV) / Double(totalColors)
//				let color = Color(hue: v, saturation: 1, brightness: 1)
//				let color: Color = .red
				
				// If the tracked line is for the current tile
				guard currentLine.color != color else {
					continue
				}
				
				// Start tracking a new line if the tracked line is for a different tile and is for an empty tile
				guard let currentLineColor = currentLine.color else {
					currentLine = (color, yCoordnate)
					continue
				}
				
				// If the tracked line is for a different tile and is not for an empty tile, store the tracked line
				let line = coloredLines[currentLineColor] ?? Line()
				let startPoint = CGPoint(x: xCoordinate, y: currentLine.start)
				let endPoint = CGPoint(x: xCoordinate, y: yCoordnate)
				line.segments.append((startPoint, endPoint))
				coloredLines[currentLineColor] = line
				
				currentLine = (color, yCoordnate)
			}
			
			guard let color = currentLine.color else {
				continue
			}
			
			// If the current line is not for an empty tile, store it
			let line = coloredLines[color] ?? Line()
			let startPoint = CGPoint(x: xCoordinate, y: currentLine.start)
			let endPoint = CGPoint(x: xCoordinate, y: heightRange.upperBound)
			line.segments.append((startPoint, endPoint))
			coloredLines[color] = line
		}
		let chunkRect = Rect(x: widthRange.lowerBound, y: heightRange.lowerBound, width: widthRange.count, height: heightRange.count)
		return [chunkRect: coloredLines]
	}
	
	private static func generatePaths(world: World) async -> MapPaths {
		return await withTaskGroup(of: [Rect: [Color: Line]].self) { group in
			let chunkSize: (width: Int, height: Int) = (1000, 500)
			
			let worldWidth = Int(world.properties.width)
			let worldHeight = Int(world.properties.height)
			
			for horizontalChunkIndex in stride(from: 0, to: worldWidth, by: chunkSize.width) {
				let horizontalChunkRange = horizontalChunkIndex ..< min(horizontalChunkIndex + chunkSize.width, worldWidth)
					
				for verticalChunkIndex in stride(from: 0, to: worldHeight, by: chunkSize.height) {
					let verticalChunkRange = verticalChunkIndex ..< min(verticalChunkIndex + chunkSize.height, worldHeight)
					
					group.addTask {
						return chunkPaths(from: world, in: verticalChunkRange, in: horizontalChunkRange)
					}
				}
			}
			var mapPaths: MapPaths = [:]
			for await chunkPaths in group {
				for (chunk, coloredLines) in chunkPaths {
					var mapPath: [Color: Path] = [:]
					for (color, line) in coloredLines {
						mapPath[color] = line.path
					}
					mapPaths[chunk] = mapPath
				}
			}
			return mapPaths
		}
	}
}
