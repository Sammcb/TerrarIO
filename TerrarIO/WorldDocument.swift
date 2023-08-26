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

class WorldDocument: ReferenceFileDocument {
	typealias MapPaths = [Color: Path]
	
	typealias Snapshot = World
	
	static var readableContentTypes: [UTType] = [.worldDocument]
	
	@Published var world = World()
	@Published var paths: MapPaths = [:]
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
	
	private static func generatePaths(world: World) async -> MapPaths {
		typealias ColoredPaths = [Color: Path]
		
		return await withTaskGroup(of: ColoredPaths.self) { group in
			let totalColors = 10
			
			let columnStride = 1000
			let worldWidth = Int(world.properties.width)
			let worldHeight = Int(world.properties.height)
			for chunkIndex in stride(from: 0, to: worldWidth, by: columnStride) {
//				if chunkIndex > 0 {
//					break
//				}
				let tileColumnsSubset = world.tiles.tiles[chunkIndex ..< min(chunkIndex + columnStride, worldWidth)]
				group.addTask {
					var chunkPaths: ColoredPaths = [:]
					chunkPaths.reserveCapacity(1000)
					for (rowIndex, tileColumn) in tileColumnsSubset.enumerated() {
						var initColorV = rowIndex
						var currentLine: (color: Color?, start: Int) = (nil, 0)
						let xCoordinate = rowIndex + chunkIndex
						for (columnIndex, tile) in tileColumn.enumerated() {
							guard columnIndex % pixelScale == 0 else {
								continue
							}
			
//							let color = pathColor(for: tile)
							// 693 possible tiles
							initColorV += 1
							if initColorV > totalColors {
								initColorV = 0
							}
							
							let v = Double(initColorV) / Double(totalColors) // max color value will be 231 < 255
							let	color = Color(red: v, green: v, blue: v)
//							let color: Color = .red
							
							// If the tracked line is for the current tile
							guard currentLine.color != color else {
								continue
							}
							
							// Start tracking a new line if the tracked line is for a different tile and is for an empty tile
							guard currentLine.color != nil else {
								currentLine = (color, columnIndex)
								continue
							}
							
							// If the tracked line is for a different tile and is not for an empty tile, store the tracked line
							var path = chunkPaths[color] ?? Path()
							let startPoint = CGPoint(x: xCoordinate, y: currentLine.start)
							let endPoint = CGPoint(x: xCoordinate, y: columnIndex)
							path.addLines([startPoint, endPoint])
							chunkPaths[color] = path
							
							currentLine = (color, columnIndex)
						}
						
						guard let color = currentLine.color else {
							continue
						}
						
						// If the current line is not for an empty tile, store it
						var path = chunkPaths[color] ?? Path()
						let startPoint = CGPoint(x: xCoordinate, y: currentLine.start)
						let endPoint = CGPoint(x: xCoordinate, y: worldHeight)
						path.addLines([startPoint, endPoint])
						chunkPaths[color] = path
					}
					return chunkPaths
				}
			}
			
			var mapPaths: MapPaths = [:]
			for await chunkPaths in group {
				for (color, path) in chunkPaths {
					guard var mapPath = mapPaths[color] else {
						mapPaths[color] = path
						continue
					}
					
					path.forEach { element in
						switch element {
						case .move(to: let point): mapPath.move(to: point)
						case .line(to: let point): mapPath.addLine(to: point)
						default: return
						}
					}
					mapPaths[color] = mapPath
				}
			}
			print(mapPaths.count)
			return mapPaths
			
//			var mapPaths: MapPaths = [:]
//			for await segmentedPathChunk in group {
//				print(segmentedPathChunk.count)
//				for (color, segmentedPath) in segmentedPathChunk {
//					guard let mapPath = mapPaths[color] else {
//						let path = segmentedPath.generatePath()
//						mapPaths[color] = path
//						continue
//					}
//
//					let path = segmentedPath.generatePath(for: mapPath)
//					mapPaths[color] = path
//				}
//			}
//
//			for (color, path) in mapPaths {
//				path.forEach { element in
//					print(element)
//				}
//			}
//
//			print("Total paths: \(mapPaths.count)")
//			return mapPaths
//			return MapPaths()
		}
	}
}
