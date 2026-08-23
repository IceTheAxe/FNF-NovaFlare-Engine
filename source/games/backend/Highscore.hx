package games.backend;

import flixel.FlxG;
import flixel.util.FlxSave;
import haxe.Serializer;

private typedef SongHistoryEntry =
{
	var details:Array<Array<Dynamic>>;
	var keyHit:Array<Array<Array<Float>>>;
	var originalIndex:Int;
	var metric:Null<Float>;
}

private typedef NormalizedSongHistory =
{
	var details:Array<Array<Array<Dynamic>>>;
	var keyHits:Array<Array<Array<Array<Float>>>>;
}

private typedef DecodedWeekScores =
{
	var value:Map<String, Int>;
	var complete:Bool;
}

private typedef DecodedSongDetails =
{
	var value:Map<String, Array<Array<Array<Dynamic>>>>;
	var complete:Bool;
}

private typedef DecodedSongKeyHits =
{
	var value:Map<String, Array<Array<Array<Array<Float>>>>>;
	var complete:Bool;
}

private typedef DecodedLegacyFields =
{
	var weekScores:Map<String, Int>;
	var songDetails:Map<String, Array<Array<Array<Dynamic>>>>;
	var songKeyHit:Map<String, Array<Array<Array<Array<Float>>>>>;
	var complete:Bool;
}

class Highscore
{
	public static inline var MAX_SONG_HISTORY:Int = 10;
	static inline var MAX_ORPHAN_KEY_HISTORY:Int = 10;
	static inline var SCORE_SAVE_NAME:String = 'highscores_v1';

	public static var weekScores:Map<String, Int> = new Map(); // 获取周的总分数

	// 获取游玩所有轨道击打的数据：歌曲 > 成绩记录 > 摁压类型 > 行数 > 时间
	public static var songKeyHit:Map<String, Array<Array<Array<Array<Float>>>>> = new Map<String, Array<Array<Array<Array<Float>>>>>();

	/**
	 * 歌曲 -> 排行记录 -> 4 组细节数据
	 * 第 1 组：songName, songLength, Date.now().toString()
	 * 第 2 组：songSpeed, playbackRate, healthGain, healthLoss,
	 *          cpuControlled, practiceMode, instakillOnMiss, playOpponent, flipChart
	 * 第 3 组：songScore, ratingPercent, ratingFC, songHits, highestCombo, songMisses
	 * 第 4 组：NoteTime, NoteMs
	 */
	public static var songDetails:Map<String, Array<Array<Array<Dynamic>>>> = new Map<String, Array<Array<Array<Dynamic>>>>();
	public static var songPlayCount:Map<String, Int> = new Map();

	static var scoreSave:FlxSave;
	static var loaded:Bool = false;

	public static function resetSong(song:String, diff:Int = 0):Void
	{
		ensureLoaded();
		var daSong:String = formatSong(song, diff);
		songKeyHit.remove(daSong);
		songDetails.remove(daSong);
		commitScoreSave();
	}

	public static function resetWeek(week:String, diff:Int = 0):Void
	{
		ensureLoaded();
		var daWeek:String = formatSong(week, diff);
		setWeekScore(daWeek, 0);
	}

	////////////////////////////////////////////////////

	public static function saveWeekScore(week:String, score:Int = 0, ?diff:Int = 0):Void
	{
		ensureLoaded();
		var daWeek:String = formatSong(week, diff);

		if (weekScores.exists(daWeek))
		{
			if (weekScores.get(daWeek) < score)
				setWeekScore(daWeek, score);
		}
		else
			setWeekScore(daWeek, score);
	}

	public static function saveGameData(song:String, diff:Int = 0, details:Array<Array<Dynamic>>, keyHit:Array<Array<Array<Float>>>):Void
	{
		ensureLoaded();
		var daSong:String = formatSong(song, diff);

		if (songPlayCount.exists(daSong))
			songPlayCount.set(daSong, songPlayCount.get(daSong) + 1);
		else
			songPlayCount.set(daSong, 1);

		if (details == null)
		{
			FlxG.log.warn('[Highscore] Ignored null details for "$daSong".');
			return;
		}

		var detailHistory:Array<Array<Array<Dynamic>>> = [];
		if (songDetails.exists(daSong) && songDetails.get(daSong) != null)
			detailHistory = songDetails.get(daSong).copy();

		var keyHitHistory:Array<Array<Array<Array<Float>>>> = [];
		if (songKeyHit.exists(daSong) && songKeyHit.get(daSong) != null)
			keyHitHistory = songKeyHit.get(daSong).copy();

		var newDetailIndex:Int = detailHistory.length;
		while (keyHitHistory.length < newDetailIndex)
			keyHitHistory.push([]);
		keyHitHistory.insert(newDetailIndex, keyHit != null ? keyHit : []);
		detailHistory.push(details);
		// PlayState currently has no key-hit payload and passes null. Keep histories
		// aligned with a serializable empty entry instead of persisting null.

		var normalized:NormalizedSongHistory = normalizeSongHistory(detailHistory, keyHitHistory);
		songDetails.set(daSong, normalized.details);
		songKeyHit.set(daSong, normalized.keyHits);
		commitScoreSave();
	}

	public static function savePlayCount(song:String, diff:Int = 0):Void
	{
		ensureLoaded();
		var daSong:String = formatSong(song, diff);

		if (songPlayCount.exists(daSong))
			songPlayCount.set(daSong, songPlayCount.get(daSong) + 1);
		else
			songPlayCount.set(daSong, 1);
	}

	////////////////////////////////////////////////////////////////////////

	static function setWeekScore(week:String, score:Int):Void
	{
		weekScores.set(week, score);
		commitScoreSave();
	}

	/** Stages all score fields and performs exactly one flush for an update. */
	static function commitScoreSave():Bool
	{
		if (!ensureScoreSave())
			return false;

		scoreSave.data.weekScores = weekScores;
		scoreSave.data.songDetails = songDetails;
		scoreSave.data.songKeyHit = songKeyHit;
		try
		{
			if (scoreSave.flush())
				return true;
		}
		catch (error:Dynamic)
		{
			FlxG.log.error('[Highscore] Failed to serialize the dedicated score save: $error');
			return false;
		}

		FlxG.log.error('[Highscore] Failed to flush the dedicated score save.');
		return false;
	}

	static function ensureScoreSave():Bool
	{
		if (scoreSave != null && scoreSave.isBound)
			return true;

		scoreSave = new FlxSave();
		try
		{
			if (scoreSave.bind(SCORE_SAVE_NAME, CoolUtil.getSavePath()))
				return true;
		}
		catch (error:Dynamic)
		{
			FlxG.log.error('[Highscore] Could not bind the dedicated score save: $error');
			return false;
		}

		FlxG.log.error('[Highscore] Could not bind the dedicated score save.');
		return false;
	}

	static inline function ensureLoaded():Void
	{
		if (!loaded)
			load();
	}

	/**
	 * Merges legacy score fields from the main save into the dedicated slot. The
	 * dedicated slot is flushed before legacy fields are removed, so a failed
	 * migration keeps the original data available for the next launch.
	 */
	public static function load():Void
	{
		loaded = true;
		weekScores = new Map();
		songDetails = new Map();
		songKeyHit = new Map();

		var mainData:Dynamic = FlxG.save != null ? FlxG.save.data : null;
		if (!ensureScoreSave())
		{
			loadLegacyFields(mainData);
			normalizeStoredHistories();
			return;
		}

		var rawDedicatedWeek:Dynamic = Reflect.field(scoreSave.data, 'weekScores');
		var rawDedicatedDetails:Dynamic = Reflect.field(scoreSave.data, 'songDetails');
		var rawDedicatedKeyHits:Dynamic = Reflect.field(scoreSave.data, 'songKeyHit');
		var decodedDedicatedWeek:DecodedWeekScores = decodeWeekScores(rawDedicatedWeek);
		var decodedDedicatedDetails:DecodedSongDetails = decodeSongDetails(rawDedicatedDetails);
		var decodedDedicatedKeyHits:DecodedSongKeyHits = decodeSongKeyHits(rawDedicatedKeyHits);
		var hasDedicatedWeek:Bool = rawDedicatedWeek != null;
		var hasDedicatedDetails:Bool = rawDedicatedDetails != null;
		var hasDedicatedKeyHits:Bool = rawDedicatedKeyHits != null;
		var hasCompleteDedicatedSave:Bool = hasDedicatedWeek
			&& hasDedicatedDetails
			&& hasDedicatedKeyHits
			&& decodedDedicatedWeek.complete
			&& decodedDedicatedDetails.complete
			&& decodedDedicatedKeyHits.complete;
		var migrated:Bool = false;

		if (hasDedicatedWeek)
			weekScores = decodedDedicatedWeek.value;
		if (hasDedicatedDetails)
			songDetails = decodedDedicatedDetails.value;
		if (hasDedicatedKeyHits)
			songKeyHit = decodedDedicatedKeyHits.value;

		var hasLegacy:Bool = hasLegacyFields(mainData);
		var decodedLegacy:DecodedLegacyFields = decodeLegacyFields(mainData);
		migrated = mergeLegacyFields(decodedLegacy);

		var normalized:Bool = normalizeStoredHistories();
		var dedicatedReady:Bool = hasCompleteDedicatedSave && !normalized;
		if (hasLegacy || migrated || normalized || (!hasCompleteDedicatedSave && (hasDedicatedWeek || hasDedicatedDetails || hasDedicatedKeyHits)))
			dedicatedReady = commitScoreSave();

		// 迁移完成后，尝试清除旧的遗留字段（不再检查安全保存状态）
		if (hasLegacy && mainData != null)
		{
			// 直接从主保存中移除旧的高分字段
			if (Reflect.hasField(mainData, 'weekScores'))
				Reflect.deleteField(mainData, 'weekScores');
			if (Reflect.hasField(mainData, 'songDetails'))
				Reflect.deleteField(mainData, 'songDetails');
			if (Reflect.hasField(mainData, 'songKeyHit'))
				Reflect.deleteField(mainData, 'songKeyHit');
			try
			{
				FlxG.save.flush();
			}
			catch (error:Dynamic)
			{
				FlxG.log.warn('[Highscore] Could not flush main save after legacy cleanup: $error');
			}
		}
	}

	static function loadLegacyFields(mainData:Dynamic):Void
	{
		if (mainData == null)
			return;

		var legacy:DecodedLegacyFields = decodeLegacyFields(mainData);
		if (legacy.weekScores != null)
			weekScores = legacy.weekScores;
		if (legacy.songDetails != null)
			songDetails = legacy.songDetails;
		if (legacy.songKeyHit != null)
			songKeyHit = legacy.songKeyHit;
	}

	static function decodeLegacyFields(mainData:Dynamic):DecodedLegacyFields
	{
		if (mainData == null)
			return {weekScores: null, songDetails: null, songKeyHit: null, complete: true};

		var decodedWeeks:DecodedWeekScores = decodeWeekScores(Reflect.field(mainData, 'weekScores'));
		var decodedDetails:DecodedSongDetails = decodeSongDetails(Reflect.field(mainData, 'songDetails'));
		var decodedKeyHits:DecodedSongKeyHits = decodeSongKeyHits(Reflect.field(mainData, 'songKeyHit'));
		return {
			weekScores: decodedWeeks.value,
			songDetails: decodedDetails.value,
			songKeyHit: decodedKeyHits.value,
			complete: decodedWeeks.complete && decodedDetails.complete && decodedKeyHits.complete
		};
	}

	static function decodeWeekScores(raw:Dynamic):DecodedWeekScores
	{
		if (raw == null)
			return {value: null, complete: true};

		var decoded:Map<String, Int> = new Map();
		var complete:Bool = true;
		try
		{
			var source:Map<String, Dynamic> = cast raw;
			for (week => rawScore in source)
			{
				if (!Std.isOfType(rawScore, Int) && !Std.isOfType(rawScore, Float))
				{
					complete = false;
					continue;
				}
				var score:Float = cast rawScore;
				if (Math.isNaN(score) || score != Math.floor(score) || score < -2147483648.0 || score > 2147483647.0)
				{
					complete = false;
					continue;
				}
				decoded.set(week, Std.int(score));
			}
		}
		catch (_:Dynamic)
		{
			complete = false;
		}
		return {value: decoded, complete: complete};
	}

	static function decodeSongDetails(raw:Dynamic):DecodedSongDetails
	{
		if (raw == null)
			return {value: null, complete: true};

		var decoded:Map<String, Array<Array<Array<Dynamic>>>> = new Map();
		var complete:Bool = true;
		try
		{
			var source:Map<String, Dynamic> = cast raw;
			for (song => rawHistory in source)
			{
				if (!Std.isOfType(rawHistory, Array))
				{
					complete = false;
					continue;
				}
				var history:Array<Array<Array<Dynamic>>> = [];
				for (rawRecord in (cast rawHistory:Array<Dynamic>))
				{
					if (rawRecord == null)
					{
						history.push(null);
						continue;
					}
					if (!Std.isOfType(rawRecord, Array))
					{
						complete = false;
						history.push(null);
						continue;
					}
					var record:Array<Array<Dynamic>> = [];
					var recordValid:Bool = true;
					for (rawGroup in (cast rawRecord:Array<Dynamic>))
					{
						if (!Std.isOfType(rawGroup, Array))
						{
							recordValid = false;
							break;
						}
						record.push((cast rawGroup:Array<Dynamic>).copy());
					}
					if (recordValid)
						history.push(record);
					else
					{
						complete = false;
						history.push(null);
					}
				}
				decoded.set(song, history);
			}
		}
		catch (_:Dynamic)
		{
			complete = false;
		}
		return {value: decoded, complete: complete};
	}

	static function decodeSongKeyHits(raw:Dynamic):DecodedSongKeyHits
	{
		if (raw == null)
			return {value: null, complete: true};

		var decoded:Map<String, Array<Array<Array<Array<Float>>>>> = new Map();
		var complete:Bool = true;
		try
		{
			var source:Map<String, Dynamic> = cast raw;
			for (song => rawHistory in source)
			{
				if (!Std.isOfType(rawHistory, Array))
				{
					complete = false;
					continue;
				}
				var history:Array<Array<Array<Array<Float>>>> = [];
				for (rawEntry in (cast rawHistory:Array<Dynamic>))
				{
					if (rawEntry == null)
					{
						history.push([]);
						continue;
					}
					var entry:Array<Array<Array<Float>>> = decodeKeyHitEntry(rawEntry);
					if (entry == null)
					{
						complete = false;
						history.push([]);
					}
					else
						history.push(entry);
				}
				decoded.set(song, history);
			}
		}
		catch (_:Dynamic)
		{
			complete = false;
		}
		return {value: decoded, complete: complete};
	}

	static function decodeKeyHitEntry(raw:Dynamic):Array<Array<Array<Float>>>
	{
		if (!Std.isOfType(raw, Array))
			return null;
		var entry:Array<Array<Array<Float>>> = [];
		for (rawType in (cast raw:Array<Dynamic>))
		{
			if (!Std.isOfType(rawType, Array))
				return null;
			var pressType:Array<Array<Float>> = [];
			for (rawLane in (cast rawType:Array<Dynamic>))
			{
				if (!Std.isOfType(rawLane, Array))
					return null;
				var lane:Array<Float> = [];
				for (rawTime in (cast rawLane:Array<Dynamic>))
				{
					if (!Std.isOfType(rawTime, Int) && !Std.isOfType(rawTime, Float))
						return null;
					var time:Float = cast rawTime;
					if (Math.isNaN(time) || time == Math.POSITIVE_INFINITY || time == Math.NEGATIVE_INFINITY)
						return null;
					lane.push(time);
				}
				pressType.push(lane);
			}
			entry.push(pressType);
		}
		return entry;
	}

	/**
	 * Merges both save slots instead of treating a merely non-null dedicated
	 * field as newer. Identical copied histories use multiset semantics, so a
	 * previous migration is not doubled while legitimate duplicate plays remain.
	 */
	static function mergeLegacyFields(legacy:DecodedLegacyFields):Bool
	{
		if (legacy == null)
			return false;

		var changed:Bool = false;
		var legacyWeeks:Map<String, Int> = legacy.weekScores;
		if (legacyWeeks != null)
			for (week => score in legacyWeeks)
				if (!weekScores.exists(week) || weekScores.get(week) < score)
				{
					weekScores.set(week, score);
					changed = true;
				}

		var legacyDetails:Map<String, Array<Array<Array<Dynamic>>>> = legacy.songDetails;
		var legacyKeyHits:Map<String, Array<Array<Array<Array<Float>>>>> = legacy.songKeyHit;
		var songs:Map<String, Bool> = new Map();
		if (legacyDetails != null)
			for (song in legacyDetails.keys())
				songs.set(song, true);
		if (legacyKeyHits != null)
			for (song in legacyKeyHits.keys())
				songs.set(song, true);

		for (song in songs.keys())
		{
			var beforeDetails = songDetails.get(song);
			var beforeKeyHits = songKeyHit.get(song);
			var combined:NormalizedSongHistory = combineSongHistories(
				beforeDetails,
				beforeKeyHits,
				legacyDetails != null ? legacyDetails.get(song) : null,
				legacyKeyHits != null ? legacyKeyHits.get(song) : null);

			if (combined.details.length > 0)
				songDetails.set(song, combined.details);
			else
				songDetails.remove(song);
			if (combined.keyHits.length > 0)
				songKeyHit.set(song, combined.keyHits);
			else
				songKeyHit.remove(song);

			if (!serializedEqual(beforeDetails, combined.details) || !serializedEqual(beforeKeyHits, combined.keyHits))
				changed = true;
		}
		return changed;
	}

	static function hasLegacyFields(mainData:Dynamic):Bool
	{
		return mainData != null
			&& (Reflect.hasField(mainData, 'weekScores')
				|| Reflect.hasField(mainData, 'songDetails')
				|| Reflect.hasField(mainData, 'songKeyHit'));
	}


	/**
	 * Combines two copies of a song history without doubling entries that were
	 * copied by an earlier migration. Key-hit entries without matching details
	 * are kept at the tail and normalized later.
	 */
	static function combineSongHistories(destinationDetails:Array<Array<Array<Dynamic>>>,
		destinationKeyHits:Array<Array<Array<Array<Float>>>>,
		sourceDetails:Array<Array<Array<Dynamic>>>,
		sourceKeyHits:Array<Array<Array<Array<Float>>>>):NormalizedSongHistory
	{
		var details:Array<Array<Array<Dynamic>>> = [];
		var keyHits:Array<Array<Array<Array<Float>>>> = [];
		var destinationOrphans:Array<Array<Array<Array<Float>>>> = [];
		var sourceOrphans:Array<Array<Array<Array<Float>>>> = [];

		var destinationDetailCount:Int = destinationDetails != null ? destinationDetails.length : 0;
		for (i in 0...destinationDetailCount)
		{
			var entryDetails = destinationDetails[i];
			var entryKeyHit:Array<Array<Array<Float>>> = destinationKeyHits != null && i < destinationKeyHits.length ? destinationKeyHits[i] : null;
			if (entryDetails == null)
			{
				if (hasKeyHitPayload(entryKeyHit))
					destinationOrphans.push(entryKeyHit);
				continue;
			}
			details.push(entryDetails);
			keyHits.push(entryKeyHit != null ? entryKeyHit : []);
		}
		if (destinationKeyHits != null)
			for (i in destinationDetailCount...destinationKeyHits.length)
				if (hasKeyHitPayload(destinationKeyHits[i]))
					destinationOrphans.push(destinationKeyHits[i]);

		var destinationIndexes:Map<String, Array<Int>> = new Map();
		for (i in 0...details.length)
		{
			var fingerprint:String = serializedValue(details[i]);
			if (!destinationIndexes.exists(fingerprint))
				destinationIndexes.set(fingerprint, []);
			destinationIndexes.get(fingerprint).push(i);
		}

		var sourceOccurrences:Map<String, Int> = new Map();
		var sourceDetailCount:Int = sourceDetails != null ? sourceDetails.length : 0;
		for (i in 0...sourceDetailCount)
		{
			var entryDetails = sourceDetails[i];
			var entryKeyHit:Array<Array<Array<Float>>> = sourceKeyHits != null && i < sourceKeyHits.length ? sourceKeyHits[i] : null;
			if (entryDetails == null)
			{
				if (hasKeyHitPayload(entryKeyHit))
					sourceOrphans.push(entryKeyHit);
				continue;
			}

			var fingerprint:String = serializedValue(entryDetails);
			var occurrence:Int = sourceOccurrences.exists(fingerprint) ? sourceOccurrences.get(fingerprint) : 0;
			sourceOccurrences.set(fingerprint, occurrence + 1);
			var matchingIndexes = destinationIndexes.get(fingerprint);
			if (matchingIndexes != null && occurrence < matchingIndexes.length)
			{
				var destinationIndex:Int = matchingIndexes[occurrence];
				if (!hasKeyHitPayload(keyHits[destinationIndex]) && hasKeyHitPayload(entryKeyHit))
					keyHits[destinationIndex] = entryKeyHit;
				continue;
			}

			var destinationIndex:Int = details.length;
			details.push(entryDetails);
			keyHits.push(entryKeyHit != null ? entryKeyHit : []);
			if (matchingIndexes == null)
			{
				matchingIndexes = [];
				destinationIndexes.set(fingerprint, matchingIndexes);
			}
			matchingIndexes.push(destinationIndex);
		}
		if (sourceKeyHits != null)
			for (i in sourceDetailCount...sourceKeyHits.length)
				if (hasKeyHitPayload(sourceKeyHits[i]))
					sourceOrphans.push(sourceKeyHits[i]);

		for (orphan in mergeOrphanKeyHits(destinationOrphans, sourceOrphans))
			keyHits.push(orphan);
		return {details: details, keyHits: keyHits};
	}

	/** Uses multiset union so a copied legacy tail is not appended twice. */
	static function mergeOrphanKeyHits(destination:Array<Array<Array<Array<Float>>>>,
		source:Array<Array<Array<Array<Float>>>>):Array<Array<Array<Array<Float>>>>
	{
		var result:Array<Array<Array<Array<Float>>>> = destination.copy();
		var destinationCounts:Map<String, Int> = new Map();
		for (entry in destination)
		{
			var fingerprint:String = serializedValue(entry);
			destinationCounts.set(fingerprint, (destinationCounts.exists(fingerprint) ? destinationCounts.get(fingerprint) : 0) + 1);
		}

		var sourceCounts:Map<String, Int> = new Map();
		for (entry in source)
		{
			var fingerprint:String = serializedValue(entry);
			var occurrence:Int = sourceCounts.exists(fingerprint) ? sourceCounts.get(fingerprint) : 0;
			sourceCounts.set(fingerprint, occurrence + 1);
			if (occurrence >= (destinationCounts.exists(fingerprint) ? destinationCounts.get(fingerprint) : 0))
				result.push(entry);
		}
		return result;
	}

	static inline function hasKeyHitPayload(entry:Array<Array<Array<Float>>>):Bool
	{
		return entry != null && entry.length > 0;
	}

	static function serializedValue(value:Dynamic):String
	{
		try
		{
			return Serializer.run(value);
		}
		catch (error:Dynamic)
		{
			return Std.string(value);
		}
	}

	static inline function serializedEqual(a:Dynamic, b:Dynamic):Bool
	{
		return serializedValue(a) == serializedValue(b);
	}

	/** Sorts complete old histories before capping and removes null key hits. */
	static function normalizeStoredHistories():Bool
	{
		var changed:Bool = false;
		var songs:Map<String, Bool> = new Map();
		for (song in songDetails.keys())
			songs.set(song, true);
		for (song in songKeyHit.keys())
			songs.set(song, true);

		for (song in songs.keys())
		{
			var oldDetails = songDetails.get(song);
			var oldKeyHits = songKeyHit.get(song);
			var comparableDetails:Array<Array<Array<Dynamic>>> = oldDetails != null ? oldDetails : [];
			var comparableKeyHits:Array<Array<Array<Array<Float>>>> = oldKeyHits != null ? oldKeyHits : [];
			var normalized:NormalizedSongHistory = normalizeSongHistory(comparableDetails, comparableKeyHits);
			if (!serializedEqual(comparableDetails, normalized.details) || !serializedEqual(comparableKeyHits, normalized.keyHits))
				changed = true;

			if (normalized.details.length > 0)
				songDetails.set(song, normalized.details);
			else
				songDetails.remove(song);
			if (normalized.keyHits.length > 0)
				songKeyHit.set(song, normalized.keyHits);
			else
				songKeyHit.remove(song);
		}
		return changed;
	}

	static function normalizeSongHistory(detailHistory:Array<Array<Array<Dynamic>>>,
		keyHitHistory:Array<Array<Array<Array<Float>>>>):NormalizedSongHistory
	{
		var metricIndex:Int = switch (ClientPrefs.data.saveScoreBase)
		{
			case 'Accuracy': 1;
			case 'Misses': 5;
			case 'highestCombo': 4;
			default: 0;
		};
		var ascending:Bool = ClientPrefs.data.saveScoreBase == 'Misses';
		var entries:Array<SongHistoryEntry> = [];
		var orphanKeyHits:Array<Array<Array<Array<Float>>>> = [];
		for (i in 0...detailHistory.length)
		{
			var entryDetails = detailHistory[i];
			if (entryDetails == null)
			{
				if (i < keyHitHistory.length && hasKeyHitPayload(keyHitHistory[i]))
					orphanKeyHits.push(keyHitHistory[i]);
				continue;
			}
			var entryKeyHit:Array<Array<Array<Float>>> = i < keyHitHistory.length ? keyHitHistory[i] : null;
			entries.push({
				details: entryDetails,
				keyHit: entryKeyHit != null ? entryKeyHit : [],
				originalIndex: i,
				metric: getHistoryMetric(entryDetails, metricIndex)
			});
		}

		entries.sort(function(a:SongHistoryEntry, b:SongHistoryEntry):Int
		{
			if (a.metric == null)
				return b.metric == null ? a.originalIndex - b.originalIndex : 1;
			if (b.metric == null)
				return -1;
			if (a.metric < b.metric)
				return ascending ? -1 : 1;
			if (a.metric > b.metric)
				return ascending ? 1 : -1;
			return a.originalIndex - b.originalIndex;
		});
		if (entries.length > MAX_SONG_HISTORY)
			entries.resize(MAX_SONG_HISTORY);
		for (i in detailHistory.length...keyHitHistory.length)
			if (hasKeyHitPayload(keyHitHistory[i]))
				orphanKeyHits.push(keyHitHistory[i]);

		var normalizedKeyHits:Array<Array<Array<Array<Float>>>> = [for (entry in entries) entry.keyHit];
		var keptOrphans:Int = 0;
		for (orphan in orphanKeyHits)
		{
			if (keptOrphans >= MAX_ORPHAN_KEY_HISTORY)
				break;
			normalizedKeyHits.push(orphan);
			keptOrphans++;
		}

		return {
			details: [for (entry in entries) entry.details],
			keyHits: normalizedKeyHits
		};
	}

	static function getHistoryMetric(details:Array<Array<Dynamic>>, metricIndex:Int):Null<Float>
	{
		if (details == null || details.length <= 2 || details[2] == null || details[2].length <= metricIndex)
			return null;

		var rawValue:Dynamic = details[2][metricIndex];
		if (rawValue == null)
			return null;
		var value:Float = Std.parseFloat(Std.string(rawValue));
		if (Math.isNaN(value) || value == Math.POSITIVE_INFINITY || value == Math.NEGATIVE_INFINITY)
			return null;
		return value;
	}

	////////////////////////////////////////////////////////////////////////

	public static function getWeekScore(week:String, diff:Int):Int
	{
		ensureLoaded();
		var daWeek:String = formatSong(week, diff);
		if (!weekScores.exists(daWeek))
			return 0;
		return weekScores.get(daWeek);
	}

	public static function getScore(song:String, diff:Int, sort:Int = 0):Int
	{
		ensureLoaded();
		var details:Dynamic = getDetails(song, diff, sort);
		if (details == null || !Std.isOfType(details, Array) || details.length <= 2 || details[2] == null || details[2].length == 0)
			return 0;
		return Std.int(details[2][0]);
	}

	public static function getPlayCount(song:String, diff:Int):Int
	{
		ensureLoaded();
		var daSong:String = formatSong(song, diff);
		if (!songPlayCount.exists(daSong))
			return 0;
		return songPlayCount.get(daSong);
	}

	public static function getDetails(song:String, diff:Int, sort:Int = 0):Dynamic
	{
		ensureLoaded();
		var daSong:String = formatSong(song, diff);
		if (!songDetails.exists(daSong))
			return [];
		var history = songDetails.get(daSong);
		if (history == null || sort < 0 || sort >= history.length)
			return [];
		return history[sort];
	}

	public static function getKeyHit(song:String, diff:Int, sort:Int = 0):Dynamic
	{
		ensureLoaded();
		var daSong:String = formatSong(song, diff);
		if (!songKeyHit.exists(daSong))
			return [[[], [], [], []], [[], [], [], []]];
		var history = songKeyHit.get(daSong);
		if (history == null || sort < 0 || sort >= history.length || history[sort] == null || history[sort].length == 0)
			return [[[], [], [], []], [[], [], [], []]];
		return history[sort];
	}

	public static function formatSong(song:String, diff:Int):String
	{
		return Paths.formatToSongPath(song) + Difficulty.getFilePath(diff);
	}
}