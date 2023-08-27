//
//  WorldView.swift
//  TerrarIO
//
//  Created by Sam McBroom on 8/23/23.
//

import SwiftUI

struct MapLine: Equatable {
	var tile = World.Tiles.Tile()
	var start: CGPoint = .zero
	var end: CGPoint = .zero
}

struct Line: Equatable {
	var color: Color
	var start: CGPoint
	var end: CGPoint
}

struct WorldView: View {
	@EnvironmentObject var document: WorldDocument
	
	private let mapCoordinateSpace = "map"
	private var linesCache: [String: Path]?
	@State private var currentZoom: Double = 0
	@State private var totalZoom: Double = 1.0
	@State private var mapFrame: CGRect = .zero
	@State private var mainFrame: CGRect = .zero
	
	private func clamp(value: Int, to range: Range<Int>) -> Int {
		min(max(value, range.lowerBound), range.upperBound)
	}
	
	var body: some View {
		VStack {
			Text(document.world.properties.name)
			Text("Version: \(document.world.header.version)")
			Text("Tile count: \(document.world.properties.width * document.world.properties.height)")
			Text("main frame: \(mainFrame.debugDescription)")
			Text("map frame: \(mapFrame.debugDescription)")
			Text("Path processing done: \(String(document.pathsDone))")
			GeometryReader { outerProxy in
				ScrollView([.horizontal, .vertical]) {
					GeometryReader { proxy in
						Canvas(opaque: true, rendersAsynchronously: false) { context, size in
							let worldWidth = Int(document.world.properties.width)
							let worldHeight = Int(document.world.properties.height)
							let visibleWidth = clamp(value: Int(mainFrame.width), to: 0 ..< worldWidth)
							let visibleHeight = clamp(value: Int(mainFrame.height), to: 0 ..< worldHeight)
							let widthOffset = clamp(value: Int(-mapFrame.origin.x), to: 0 ..< worldWidth - visibleWidth)
							let heightOffset = clamp(value: Int(-mapFrame.origin.y), to: 0 ..< worldHeight - visibleHeight)
							let visibleRect = CGRect(x: widthOffset, y: heightOffset, width: visibleWidth, height: visibleHeight)
							for (chunk, colorPaths) in document.paths {
								guard chunk.cgRect.intersects(visibleRect) else {
									continue
								}
								for (color, path) in colorPaths {
									context.stroke(path, with: .color(color), lineWidth: CGFloat(WorldDocument.pixelScale))
								}
							}
						}
						.frame(width: CGFloat(document.world.properties.width), height: CGFloat(document.world.properties.height))
						.onChange(of: proxy.frame(in: .named(mapCoordinateSpace))) { newFrame in
							mapFrame = newFrame
						}
					}
					.frame(width: CGFloat(document.world.properties.width), height: CGFloat(document.world.properties.height))
				}
				.coordinateSpace(name: mapCoordinateSpace)
				.frame(maxWidth: .infinity, maxHeight: .infinity)
				.onChange(of: outerProxy.frame(in: .local)) { newFrame in
					mainFrame = newFrame
				}
				.padding()
			}
		}
	}
}
