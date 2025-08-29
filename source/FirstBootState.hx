package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxBackdrop;
import flixel.addons.transition.FlxTransitionableState;
import flixel.effects.FlxFlicker;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import shaders.ColorMaskShader;

class FirstBootState extends MusicBeatState
{
	var textMenuItems:Array<String> = [];
	var localeList:Array<String> = [];

	var selectedsomething:Bool = false;

	var curSelected:Int = 0;

	var backdrop:FlxBackdrop;
	var gradient:FlxSprite;
	var creditsBG:FlxBackdrop;
	var scanline:FlxBackdrop;
	var funnynote:FlxSprite;
    var fg:FlxSprite;
    var bg:FlxSprite;
	var grpOptionsTexts:FlxTypedGroup<FlxText>;

	override function create()
	{
		persistentUpdate = persistentDraw = true;

		backdrop = new FlxBackdrop(Paths.image('scrollingBG'));
		backdrop.velocity.set(-10, 0);
		backdrop.antialiasing = SaveData.globalAntialiasing;
		backdrop.shader = new ColorMaskShader(0xFFFDFFFF, 0xFF7fedf0);
		add(backdrop);

		creditsBG = new FlxBackdrop(Paths.image('credits/pocBackground', 'doki'));
		creditsBG.velocity.set(-50, 0);
		creditsBG.antialiasing = SaveData.globalAntialiasing;
		add(creditsBG);

		scanline = new FlxBackdrop(Paths.image('credits/scanlines', 'doki'));
		scanline.velocity.set(0, 20);
		scanline.antialiasing = SaveData.globalAntialiasing;
		add(scanline);

		gradient = new FlxSprite().loadGraphic(Paths.image('credits/gradent', 'doki'));
		gradient.antialiasing = SaveData.globalAntialiasing;
		gradient.scrollFactor.set(0.1, 0.1);
		gradient.screenCenter();
		gradient.setGraphicSize(Std.int(gradient.width * 1.4));
		add(gradient);

		backdrop.alpha = 1;
		gradient.alpha = 1;
		creditsBG.alpha = 1;
		scanline.alpha = 1;

		#if FEATURE_LANGUAGE
		bg = new FlxSprite().loadGraphic(Paths.image('language/background'));
		bg.antialiasing = SaveData.globalAntialiasing;
		add(bg);

		fg = new FlxSprite().loadGraphic(Paths.image('language/overlay'));
		fg.antialiasing = SaveData.globalAntialiasing;
		add(fg);
 
/*
		var titleText:FlxText = new FlxText(200, 6, 0, 'Select Language');
		titleText.setFormat(LangUtil.getFont('grotesk'), 18, 0xFF1A5057, CENTER);
		titleText.y += LangUtil.getFontOffset('grotesk');
		titleText.antialiasing = SaveData.globalAntialiasing;
		add(titleText);  */
		bg.alpha = 1;
		fg.alpha = 1;

		localeList = CoolUtil.coolTextFile(Paths.txt('locales/sort', 'preload'));

		for (i in 0...localeList.length)
			textMenuItems.push(Main.tongue.getIndexString(LanguageBilingual, localeList[i]));

		grpOptionsTexts = new FlxTypedGroup<FlxText>();
		add(grpOptionsTexts);

		for (i in 0...textMenuItems.length)
		{
			var optionText:FlxText = new FlxText(252, 96 + (i * 43), 0, textMenuItems[i]);
			optionText.setFormat(LangUtil.getFont('riffic'), 27, FlxColor.WHITE, LEFT);
			optionText.antialiasing = SaveData.globalAntialiasing;
			optionText.ID = i;
			grpOptionsTexts.add(optionText);
		}

		FlxTween.tween(fg, {alpha:  1}, 0.5, {ease: FlxEase.quadOut});
		FlxTween.tween(bg, {alpha:  1}, 0.5, {ease: FlxEase.quadOut});
		#else

		FlxTween.tween(backdrop, {alpha: 1}, 0.5, {ease: FlxEase.quadOut});
		FlxTween.tween(gradient, {alpha: 1}, 0.5, {ease: FlxEase.quadOut});
		FlxTween.tween(creditsBG, {alpha: 1}, 0.5, {ease: FlxEase.quadOut});
		FlxTween.tween(scanline, {alpha:  1}, 0.5, {ease: FlxEase.quadOut});

		selectedSomethin = true;
		bringinthenote();
		#end

		super.create();
	}

	var selectedSomethin:Bool = false;

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (controls.ACCEPT && selectedSomethin && !selectedsomething)
		{
			FlxG.sound.play(Paths.sound('exitOS', 'preload'));

			FlxTween.tween(funnynote, {"scale.x": 0, "scale.y": 0, alpha: 0}, 0.5, {ease: FlxEase.quadOut});
			FlxTween.tween(backdrop, {alpha: 0}, 1, {ease: FlxEase.quadOut});
			FlxTween.tween(creditsBG, {alpha: 0}, 1, {ease: FlxEase.quadOut});
			FlxTween.tween(scanline, {alpha: 0}, 1, {ease: FlxEase.quadOut});

			#if FEATURE_LANGUAGE
			FlxTween.tween(fg, {alpha: 0}, 1, {ease: FlxEase.quadOut});
			FlxTween.tween(bg, {alpha: 0}, 1, {ease: FlxEase.quadOut}); 
			#end

			FlxTween.tween(gradient, {alpha: 0}, 1, 
			{
				ease: FlxEase.quadOut,
				onComplete: function(twn:FlxTween)
				{
					funnynote.kill();
					SaveData.saveStarted = true;
					SaveData.save();
					FlxTransitionableState.skipNextTransIn = true;
					FlxTransitionableState.skipNextTransOut = true;
					MusicBeatState.switchState(new TitleState());
				}
			});
		}

		#if FEATURE_LANGUAGE
		if (!selectedSomethin)
		{
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
					txt.setBorderStyle(OUTLINE, 0xFF37D3D5, 2);
				else
					txt.setBorderStyle(OUTLINE, 0xFF1A5057, 2);
			});

			if (controls.ACCEPT)
			{
				selectedsomething = true;
				selectedSomethin = true;
				FlxG.sound.play(Paths.sound('confirmMenu'));
				grpOptionsTexts.forEach(function(txt:FlxText)
				{
					if (curSelected != txt.ID)
					{
						FlxTween.tween(txt, {alpha: 0}, 1, {
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
								new FlxTimer().start(0.5, function(tmr:FlxTimer)
								{
									bringinthenote();
								});
							});
						}
						else
						{
							new FlxTimer().start(1, function(tmr:FlxTimer)
							{
								new FlxTimer().start(0.5, function(tmr:FlxTimer)
								{
									bringinthenote();
								});
							});
						}
					}
				});
			FlxTween.tween(fg, {"scale.x": 0, "scale.y": 0, alpha: 0}, 0.5, {ease: FlxEase.quadOut});
			FlxTween.tween(bg, {"scale.x": 0, "scale.y": 0, alpha: 0}, 0.5, {ease: FlxEase.quadOut});
			}
		}
		#end
	}

	function bringinthenote()
	{
		FlxG.sound.play(Paths.sound('openOS', 'preload'));

		funnynote = new FlxSprite(0, 0).loadGraphic(Paths.image('alittlebitmoretasteless', 'preload', true));
		funnynote.antialiasing = SaveData.globalAntialiasing;
		funnynote.screenCenter();
		funnynote.scale.set();
		add(funnynote);

		FlxTween.tween(funnynote, {alpha: 1}, 0.3, {ease: FlxEase.quadOut});
		FlxTween.tween(funnynote, {"scale.x": 1}, 0.15, {ease: FlxEase.quadOut});

		FlxTween.tween(funnynote, {"scale.y": 1}, 0.5, {
			ease: FlxEase.quadOut,
			onComplete: function(twn:FlxTween)
			{
				selectedsomething = false;
			}
		});
	}
}
