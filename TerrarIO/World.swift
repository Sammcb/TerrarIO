//
//  World.swift
//  TerrarIO
//
//  Created by Sam McBroom on 8/23/23.
//

import Foundation

struct World {
	// tmp store og data to write back for now
	let data: Data
	
	let header: World.Header
	let properties: World.Properties
	let tiles: World.Tiles
	
	struct Bounds {
		let left: Int32
		let right: Int32
		let top: Int32
		let bottom: Int32
		
		init(boundsList: [Int32]) {
			left = boundsList[0]
			right = boundsList[1]
			top = boundsList[2]
			bottom = boundsList[3]
		}
	}

	enum GameMode: Int32 {
		case classic, expert, master, journey
	}

	enum GeneratorType {
		case normal, drunk, getGood, tenthAnniversary, dontStarve, notTheBees, remix, noTraps, zenith
	}
	
	struct Header: WorldReader {
		private let expectedFormat = "relogic"
		let version: Int32
		let format: String
		let fileType: UInt8
		let revision: UInt32
		let isFavorite: Bool
		private let numSections: Int16
		let sectionLocations: [Int32]
		private let numMaskTiles: Int16
		let tilesHasUVCoordinates: [Bool]
		
		init() {
			version = 0
			format = ""
			fileType = 0
			revision = 0
			isFavorite = false
			numSections = 0
			sectionLocations = []
			numMaskTiles = 0
			tilesHasUVCoordinates = []
		}
		
		init(from headerOffset: Int = 0, in data: Data) {
			var offset = headerOffset
			(offset, version) = Self.readValue(from: offset, in: data)
			(offset, format) = Self.readRawString(size: expectedFormat.count, from: offset, in: data)
			(offset, fileType) = Self.readValue(from: offset, in: data)
			(offset, revision) = Self.readValue(from: offset, in: data)
			(offset, isFavorite) = Self.readValue(with: UInt64.self, from: offset, in: data)
			(offset, numSections) = Self.readValue(from: offset, in: data)
			(offset, sectionLocations) = Self.readValues(length: numSections, from: offset, in: data)
			(offset, numMaskTiles) = Self.readValue(from: offset, in: data)
			(offset, tilesHasUVCoordinates) = Self.readBitList(length: Int(numMaskTiles), from: offset, in: data)
		}
	}
	
	struct Properties: WorldReader {
		let name: String
		let seed: String
		let generatorVersion: UInt64
		private let rawUUID: [UInt8]
		var uuid: String {
			rawUUID.map({ String($0) }).joined()
		}
		let id: Int32
		private let rawBounds: [Int32]
		var bounds: Bounds {
			Bounds(boundsList: rawBounds)
		}
		let height: Int32
		let width: Int32
		private let rawGameMode: Int32
		var gameMode: GameMode {
			GameMode(rawValue: rawGameMode) ?? .classic
		}
		private let isDrunk: Bool
		private let isGetGood: Bool
		private let isTenthAnniversary: Bool
		private let isDontStarve: Bool
		private let isNotTheBees: Bool
		private let isRemix: Bool
		private let isNoTraps: Bool
		private let isZenith: Bool
		var generatorType: GeneratorType {
			if isDrunk {
				return .drunk
			} else if isGetGood {
				return .getGood
			} else if isTenthAnniversary {
				return .tenthAnniversary
			} else if isDontStarve {
				return .dontStarve
			} else if isNotTheBees {
				return .notTheBees
			} else if isRemix {
				return .remix
			} else if isNoTraps {
				return .noTraps
			} else if isZenith {
				return .zenith
			}
			return .normal
		}
		let creationTime: Int64
		let moonType: UInt8
		let treeTypeXCoordinates: [Int32]
		let treeStyles: [Int32]
		let caveBackXCoordinates: [Int32]
		let caveBackStyles: [Int32]
		let iceBackStyle: Int32
		let jungleBackStyle: Int32
		let hellBackStyle: Int32
		let spawnX: Int32
		let spawnY: Int32
		let worldSurfaceY: Double
		let rockLayerY: Double
		let gameTime: Double
		let isDay: Bool
		let moonPhase: Int32
		let isBloodMoon: Bool
		let isEclipse: Bool
		let dungeonX: Int32
		let dungeonY: Int32
		let isCrimson: Bool
		let killedEyeOfCthulu: Bool
		let killedEaterOfWorlds: Bool
		let killedSkeletron: Bool
		let killedQueenBee: Bool
		let killedTheDestroyer: Bool
		let killedTheTwins: Bool
		let killedSkeletronPrime: Bool
		let killedAnyHardmodeBoss: Bool
		let killedPlantera: Bool
		let killedGolem: Bool
		let killedSlimeKing: Bool
		
		init() {
			name = ""
			seed = ""
			generatorVersion = 0
			rawUUID = []
			id = 0
			rawBounds = []
			height = 0
			width = 0
			rawGameMode = 0
			isDrunk = false
			isGetGood = false
			isTenthAnniversary = false
			isDontStarve = false
			isNotTheBees = false
			isRemix = false
			isNoTraps = false
			isZenith = false
			creationTime = 0
			moonType = 0
			treeTypeXCoordinates = []
			treeStyles = []
			caveBackXCoordinates = []
			caveBackStyles = []
			iceBackStyle = 0
			jungleBackStyle = 0
			hellBackStyle = 0
			spawnX = 0
			spawnY = 0
			worldSurfaceY = 0
			rockLayerY = 0
			gameTime = 0
			isDay = false
			moonPhase = 0
			isBloodMoon = false
			isEclipse = false
			dungeonX = 0
			dungeonY = 0
			isCrimson = false
			killedEyeOfCthulu = false
			killedEaterOfWorlds = false
			killedSkeletron = false
			killedQueenBee = false
			killedTheDestroyer = false
			killedTheTwins = false
			killedSkeletronPrime = false
			killedAnyHardmodeBoss = false
			killedPlantera = false
			killedGolem = false
			killedSlimeKing = false
		}

		init(from propertiesOffset: Int32, in data: Data) {
			var offset = Int(propertiesOffset)
			(offset, name) = Self.readValue(from: offset, in: data)
			(offset, seed) = Self.readValue(from: offset, in: data)
			(offset, generatorVersion) = Self.readValue(from: offset, in: data)
			(offset, rawUUID) = Self.readValues(length: 16, from: offset, in: data)
			(offset, id) = Self.readValue(from: offset, in: data)
			(offset, rawBounds) = Self.readValues(length: 4, from: offset, in: data)
			(offset, height) = Self.readValue(from: offset, in: data)
			(offset, width) = Self.readValue(from: offset, in: data)
			(offset, rawGameMode) = Self.readValue(from: offset, in: data)
			(offset, isDrunk) = Self.readValue(from: offset, in: data)
			(offset, isGetGood) = Self.readValue(from: offset, in: data)
			(offset, isTenthAnniversary) = Self.readValue(from: offset, in: data)
			(offset, isDontStarve) = Self.readValue(from: offset, in: data)
			(offset, isNotTheBees) = Self.readValue(from: offset, in: data)
			(offset, isRemix) = Self.readValue(from: offset, in: data)
			(offset, isNoTraps) = Self.readValue(from: offset, in: data)
			(offset, isZenith) = Self.readValue(from: offset, in: data)
			(offset, creationTime) = Self.readValue(from: offset, in: data)
			(offset, moonType) = Self.readValue(from: offset, in: data)
			(offset, treeTypeXCoordinates) = Self.readValues(length: 3, from: offset, in: data)
			(offset, treeStyles) = Self.readValues(length: 4, from: offset, in: data)
			(offset, caveBackXCoordinates) = Self.readValues(length: 3, from: offset, in: data)
			(offset, caveBackStyles) = Self.readValues(length: 4, from: offset, in: data)
			(offset, iceBackStyle) = Self.readValue(from: offset, in: data)
			(offset, jungleBackStyle) = Self.readValue(from: offset, in: data)
			(offset, hellBackStyle) = Self.readValue(from: offset, in: data)
			(offset, spawnX) = Self.readValue(from: offset, in: data)
			(offset, spawnY) = Self.readValue(from: offset, in: data)
			(offset, worldSurfaceY) = Self.readValue(from: offset, in: data)
			(offset, rockLayerY) = Self.readValue(from: offset, in: data)
			(offset, gameTime) = Self.readValue(from: offset, in: data)
			(offset, isDay) = Self.readValue(from: offset, in: data)
			(offset, moonPhase) = Self.readValue(from: offset, in: data)
			(offset, isBloodMoon) = Self.readValue(from: offset, in: data)
			(offset, isEclipse) = Self.readValue(from: offset, in: data)
			(offset, dungeonX) = Self.readValue(from: offset, in: data)
			(offset, dungeonY) = Self.readValue(from: offset, in: data)
			(offset, isCrimson) = Self.readValue(from: offset, in: data)
			(offset, killedEyeOfCthulu) = Self.readValue(from: offset, in: data)
			(offset, killedEaterOfWorlds) = Self.readValue(from: offset, in: data)
			(offset, killedSkeletron) = Self.readValue(from: offset, in: data)
			(offset, killedQueenBee) = Self.readValue(from: offset, in: data)
			(offset, killedTheDestroyer) = Self.readValue(from: offset, in: data)
			(offset, killedTheTwins) = Self.readValue(from: offset, in: data)
			(offset, killedSkeletronPrime) = Self.readValue(from: offset, in: data)
			(offset, killedAnyHardmodeBoss) = Self.readValue(from: offset, in: data)
			(offset, killedPlantera) = Self.readValue(from: offset, in: data)
			(offset, killedGolem) = Self.readValue(from: offset, in: data)
			(offset, killedSlimeKing) = Self.readValue(from: offset, in: data)
		}
	}
	
	struct Tiles: WorldReader {
		struct Tile: Equatable {
			private func isolateBits<T: BinaryInteger>(_ flags: T, mask: T) -> T {
				flags & mask
			}
			
			private func isBitSet<T: BinaryInteger>(_ flags: T, mask: T) -> Bool {
				isolateBits(flags, mask: mask) > 0
			}
			
			enum Liquid: UInt8 {
				case none, water, lava, honey, shimmer
			}
			
			enum Slope: UInt16 {
				// Not sure of other values
				case none, half
			}
			
			enum RLEField: UInt8 {
				case none, small, large
			}
			
			var activeFlags: UInt8 = 0
			var tileFlags: UInt16 = 0
			var tileId: Int16 = 0
			var hasUVCoordiantes = false
			var textureUCoordinate: Int16 = 0
			var textureVCoordinate: Int16 = 0
			var tileColor: UInt8 = 0
			var wallId: Int16 = 0
			var wallColor: UInt8 = 0
			var liquidAmount: UInt8 = 0
			
			var hasTileFlags: Bool {
				isBitSet(activeFlags, mask: 0b1)
			}
			var hasUpperTileFlags: Bool {
				isBitSet(tileFlags, mask: 0b1)
			}
			var hasTile: Bool {
				isBitSet(activeFlags, mask: 0b10)
			}
			var hasUpperTileId: Bool {
				isBitSet(activeFlags, mask: 0b100000)
			}
			var isTilePainted: Bool {
				isBitSet(tileFlags, mask: 0b00001000_00000000)
			}
			var hasWall: Bool {
				isBitSet(activeFlags, mask: 0b100)
			}
			var hasUpperWallId: Bool {
				isBitSet(tileFlags, mask: 0b00001000_00000000)
			}
			var isWallPainted: Bool {
				isBitSet(tileFlags, mask: 0b00010000_00000000)
			}
			var liquidType: Liquid {
				// Is shimmer mutually exclusive with other liquids or can a tile be both?
				// The shimmer bit is different but maybe it's just due to it being added later
				guard !isBitSet(tileFlags, mask: 0b10000000_00000000) else {
					return .shimmer
				}
				let liquidFlags = isolateBits(activeFlags, mask: 0b11000)
				return Liquid(rawValue: liquidFlags >> 3) ?? .none
			}
			var rleLength: RLEField {
				let rleFlags = isolateBits(activeFlags, mask: 0b11000000)
				return RLEField(rawValue: rleFlags >> 6) ?? .none
			}
			var isActive: Bool {
				hasTile && !isActuated
			}
			var hasRedWire: Bool {
				isBitSet(tileFlags, mask: 0b10)
			}
			var hasGreenWire: Bool {
				isBitSet(tileFlags, mask: 0b100)
			}
			var hasBlueWire: Bool {
				isBitSet(tileFlags, mask: 0b1000)
			}
			var hasYellowWire: Bool {
				isBitSet(tileFlags, mask: 0b00100000_00000000)
			}
			var slope: Slope {
				let slopeFlags = isolateBits(tileFlags, mask: 0b1110000)
				return Slope(rawValue: slopeFlags >> 4) ?? .none
			}
			var hasActuator: Bool {
				isBitSet(tileFlags, mask: 0b00000010_00000000)
			}
			var isActuated: Bool {
				isBitSet(tileFlags, mask: 0b00000100_00000000)
			}
		}
		
		let tiles: [[Tile]]
		let size: Int
		
		init() {
			tiles = []
			size = 0
		}
		
		init(from tilesOffset: Int32, in data: Data, with header: World.Header, _ properties: World.Properties) {
			let byteSize = UInt8.bitWidth
			var offset = Int(tilesOffset)
			var processedTiles: [[Tile]] = []
			for _ in 0 ..< properties.width {
				var tileColumn: [Tile] = []
				for columnIndex in 0 ..< properties.height {
					guard tileColumn.count <= columnIndex else {
						continue
					}
					
					var tile = Tile()
					(offset, tile.activeFlags) = Self.readValue(from: offset, in: data)
					
					if tile.hasTileFlags {
						let lowerTileFlags: UInt8
						(offset, lowerTileFlags) = Self.readValue(from: offset, in: data)
						tile.tileFlags = UInt16(lowerTileFlags)
						
						if tile.hasUpperTileFlags {
							var upperTileFlags: UInt8
							(offset, upperTileFlags) = Self.readValue(from: offset, in: data)
							tile.tileFlags |= UInt16(upperTileFlags) << byteSize
						}
						
						// Not sure why this is needed
						if tile.tileFlags & 0b00000001_00000000 > 0 {
							offset += MemoryLayout<UInt8>.size
						}
					}
					
					if tile.hasTile {
						let lowerTileId: UInt8
						(offset, lowerTileId) = Self.readValue(from: offset, in: data)
						tile.tileId = Int16(lowerTileId)
						
						if tile.hasUpperTileId {
							let upperTileId: UInt8
							(offset, upperTileId) = Self.readValue(from: offset, in: data)
							tile.tileId |= Int16(upperTileId) << byteSize
						}
						
						tile.hasUVCoordiantes = header.tilesHasUVCoordinates[Int(tile.tileId)]
						
						if tile.hasUVCoordiantes {
							(offset, tile.textureUCoordinate) = Self.readValue(from: offset, in: data)
							(offset, tile.textureVCoordinate) = Self.readValue(from: offset, in: data)
							// Not sure why this is needed
							// Tile id of timer?
							if tile.tileId == 144 {
								tile.textureVCoordinate = 0
							}
						}
						
						if tile.isTilePainted {
							(offset, tile.tileColor) = Self.readValue(from: offset, in: data)
						}
					}
					
					if tile.hasWall {
						let wallIdLowByte: UInt8
						(offset, wallIdLowByte) = Self.readValue(from: offset, in: data)
						tile.wallId = Int16(wallIdLowByte)
						
						if tile.isWallPainted {
							(offset, tile.wallColor) = Self.readValue(from: offset, in: data)
						}
					}
					
					if tile.liquidType != .none {
						(offset, tile.liquidAmount) = Self.readValue(from: offset, in: data)
					}
					
					if tile.hasUpperWallId {
						let upperWallId: UInt8
						(offset, upperWallId) = Self.readValue(from: offset, in: data)
						tile.wallId |= Int16(upperWallId) << byteSize
					}
					
					tileColumn.append(tile)
					
					guard tile.rleLength != .none else {
						continue
					}
					
					var duplicateTiles: Int16 = 0
					let lowerRLECount: UInt8
					(offset, lowerRLECount) = Self.readValue(from: offset, in: data)
					duplicateTiles = Int16(lowerRLECount)
					if tile.rleLength == .large {
						let upperRLECount: UInt8
						(offset, upperRLECount) = Self.readValue(from: offset, in: data)
						duplicateTiles |= Int16(upperRLECount) << byteSize
					}
					
					for _ in 0 ..< duplicateTiles {
						tileColumn.append(tile)
					}
				}
				
				processedTiles.append(tileColumn)
			}
			tiles = processedTiles
			size = offset
		}
	}
	
	init() {
		data = Data()
		header = Header()
		properties = Properties()
		tiles = Tiles()
	}
	
	init(_ data: Data) {
		self.data = data
		header = World.Header(in: data)
		let propertiesOffset = header.sectionLocations[0]
		properties = World.Properties(from: propertiesOffset, in: data)
		let tilesOffset = header.sectionLocations[1]
		tiles = World.Tiles(from: tilesOffset, in: data, with: header, properties)		
	}
}
