#if FEATURE_LANGUAGE
package;

import flixel.FlxG;
import flixel.FlxCamera;
import flixel.FlxSprite;
import flixel.addons.display.FlxBackdrop;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.effects.FlxFlicker;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import shaders.ColorMaskShader;
import openfl.display.BlendMode;
import openfl.display.StageQuality;
import openfl.filters.ShaderFilter;
import shaders.*;
import flixel.input.mouse.FlxMouseEventManager;
using StringTools;

class LangSelectState extends MusicBeatState
{
	var mouseManager:FlxMouseEventManager = new FlxMouseEventManager();

	var backdrop:FlxBackdrop;
	var creditsBG:FlxBackdrop;
	var scanline:FlxBackdrop;
	var gradient:FlxSprite;

	var fishy:FishEyeShader = new FishEyeShader();

	var curSelected:Int = 0;

	var textMenuItems:Array<String> = [];
	var localeList:Array<String> = [];

	var grpOptionsTexts:FlxTypedGroup<FlxText>;

	override function create()
	{

		Paths.clearStoredMemory();
		Paths.clearUnusedMemory();

		persistentUpdate = persistentDraw = true;

		FlxG.sound.play(Paths.sound('openOS', 'preload'));

		backdrop = new FlxBackdrop(Paths.image('scrollingBG'));
		backdrop.velocity.set(-10, 0);
		backdrop.antialiasing = SaveData.globalAntialiasing;
		backdrop.shader = new ColorMaskShader(0xFFFDFFFF, 0xFF7fedf0);
		add(backdrop);

		creditsBG = new FlxBackdrop(Paths.image('credits/pocBackground', 'doki'));
		creditsBG.velocity.set(-50, 0);
		creditsBG.antialiasing = SaveData.globalAntialiasing;
		add(creditsBG);

		var scanline:FlxBackdrop = new FlxBackdrop(Paths.image('credits/scanlines', 'doki'));
		scanline.velocity.set(0, 20);
		scanline.antialiasing = SaveData.globalAntialiasing;
		add(scanline);

		var gradient:FlxSprite = new FlxSprite().loadGraphic(Paths.image('credits/gradent', 'doki'));
		gradient.antialiasing = SaveData.globalAntialiasing;
		gradient.scrollFactor.set(0.1, 0.1);
		gradient.screenCenter();
		gradient.setGraphicSize(Std.int(gradient.width * 1.4));
		add(gradient);

/*
						if (SaveData.shaders)
						{
						  
							var funnyShader:FishEyeShader = new FishEyeShader();
							FlxG.camera.filters = [new ShaderFilter(funnyShader)];
						}  */

		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('language/background'));
		bg.antialiasing = SaveData.globalAntialiasing;
		add(bg);

		// Featuring: working around dumb library issues
		// https://github.com/larsiusprime/firetongue/issues/48
		localeList = CoolUtil.coolTextFile(Paths.txt('locales/sort', 'preload'));

		for (i in 0...localeList.length)
			textMenuItems.push(Main.tongue.getIndexString(LanguageBilingual, localeList[i]));

		grpOptionsTexts = new FlxTypedGroup<FlxText>();
		add(grpOptionsTexts);

		for (i in 0...textMenuItems.length)
		{
			var optionText:FlxText = new FlxText(252, 96 + (i * 43), 0, textMenuItems[i]);
			optionText.setFormat(LangUtil.getFont('riffic'), 27, FlxColor.WHITE, LEFT);
			optionText.borderStyle = OUTLINE;
			optionText.borderColor = 0xFF1A5057;
			optionText.antialiasing = SaveData.globalAntialiasing;
			optionText.ID = i;
			grpOptionsTexts.add(optionText);
		}

		var fg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('language/overlay'));
		fg.antialiasing = SaveData.globalAntialiasing;
		add(fg);

		var titleText:FlxText = new FlxText(200, 6, 0, LangUtil.getString('cmnLanguage'));
		titleText.setFormat(LangUtil.getFont('grotesk'), 18, 0xFF1A5057, CENTER);
		titleText.y += LangUtil.getFontOffset('grotesk');
		titleText.antialiasing = SaveData.globalAntialiasing;
		add(titleText);

		super.create();
	}

	var selectedSomethin:Bool = false;

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (!selectedSomethin)
		{
			if (controls.BACK)
			{
				selectedSomethin = true;
				FlxG.sound.play(Paths.sound('exitOS'));
				MusicBeatState.switchState(new OptionsState());
			}

			if (controls.UP_P)
			{
				FlxG.sound.play(Paths.sound('scrollMenu'));
				curSelected -= 1;
			}

			if (controls.DOWN_P)
			{
				FlxG.sound.play(Paths.sound('scrollMenu'));
				curSelected += 1;
			}

			if (curSelected < 0)
				curSelected = textMenuItems.length - 1;

			if (curSelected >= textMenuItems.length)
				curSelected = 0;

			grpOptionsTexts.forEach(function(txt:FlxText)
			{
				if (txt.ID == curSelected)
					txt.setBorderStyle(OUTLINE, 0xFF37D3D5);
				else
					txt.setBorderStyle(OUTLINE, 0xFF1A5057);
			});

			if (controls.ACCEPT)
			{
				selectedSomethin = true;
				FlxG.sound.play(Paths.sound('confirmMenu'));

				grpOptionsTexts.forEach(function(txt:FlxText)
				{
					if (curSelected != txt.ID)
					{
						FlxTween.tween(txt, {alpha: 0}, 1.3, {
							ease: FlxEase.quadOut,
							onComplete: function(twn:FlxTween)
							{
								txt.kill();
							}
						});
					}
					else
					{
						SaveData.language = localeList[curSelected];
						trace('Game language set to ${SaveData.language}');
						Main.tongue.initialize({locale: SaveData.language});

						if (SaveData.flashing)
						{
							FlxFlicker.flicker(txt, 1, 0.06, false, false, function(flick:FlxFlicker)
							{
								FlxG.sound.play(Paths.sound('exitOS'));
								MusicBeatState.switchState(new OptionsState());
							});
						}
						else
						{
							new FlxTimer().start(1, function(tmr:FlxTimer)
							{
								FlxG.sound.play(Paths.sound('exitOS'));
								MusicBeatState.switchState(new OptionsState());
							});
						}
					}
				});
			}
		}
	}
}
#end
