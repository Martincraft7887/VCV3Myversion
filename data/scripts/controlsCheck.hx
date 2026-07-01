import flixel.input.keyboard.FlxKey;
import funkin.backend.assets.ModsFolder;
import haxe.xml.Access;
import haxe.xml.Parser;
import flixel.input.gamepad.FlxGamepadInputID;
import haxe.xml.Printer;
import Xml;
























function create()
{	
	loadBinds();
}

public function loadBinds()
{
	
	
	var xmlPath = Paths.xml('multikeyData');
	if (!Assets.exists(xmlPath))
	{
		trace('multikey data is missing!');
		return;
	}
	var plainXML = Assets.getText(xmlPath);
	var mainXML = Xml.parse(plainXML);

	var kc = 0;
	for (keyData in mainXML.elementsNamed("defaultBinds"))
	{
		for (keyGroup in keyData.elementsNamed("keyGroup"))
		{
			var knum = 0;
			for (key in keyGroup.elementsNamed("key")) 
			{
				if (Reflect.getProperty(FlxG.save.data, (kc+1)+"k"+knum) == null) 
				{
					if (key.get("bind") != "")
						Reflect.setProperty(FlxG.save.data, (kc+1)+"k"+knum, FlxKey.fromString(key.get("bind")));	
					else
						Reflect.setProperty(FlxG.save.data, (kc+1)+"k"+knum, 0);			
				}

				if (Reflect.getProperty(FlxG.save.data, (kc+1)+"k"+knum+"p2") == null)
				{
					if (key.get("bindP2") != "")
						Reflect.setProperty(FlxG.save.data, (kc+1)+"k"+knum+"p2", FlxKey.fromString(key.get("bindP2")));
					else 
						Reflect.setProperty(FlxG.save.data, (kc+1)+"k"+knum+"p2", 0);
				}

				if (Reflect.getProperty(FlxG.save.data, (kc+1)+"k"+knum+"gamepad") == null)
				{
					if (key.get("gamepadBind") != "")
						Reflect.setProperty(FlxG.save.data, (kc+1)+"k"+knum+"gamepad", FlxGamepadInputID.fromString(key.get("gamepadBind")));
					else 
						Reflect.setProperty(FlxG.save.data, (kc+1)+"k"+knum+"gamepad", -1);
				}
				if (Reflect.getProperty(FlxG.save.data, (kc+1)+"k"+knum+"gamepadP2") == null)
				{
					if (key.get("gamepadBindP2") != "")
						Reflect.setProperty(FlxG.save.data, (kc+1)+"k"+knum+"gamepadP2", FlxGamepadInputID.fromString(key.get("gamepadBindP2")));
					else 
						Reflect.setProperty(FlxG.save.data, (kc+1)+"k"+knum+"gamepadP2", -1);
				}

				knum++;
			}
			kc++;
		}
	}
}

public function resetBindsForKeyCount(kc:Int)
{
	for (i in 0...kc)
	{
		Reflect.setProperty(FlxG.save.data, (kc)+"k"+i, null);
		Reflect.setProperty(FlxG.save.data, (kc)+"k"+i+"p2", null);
	}
	loadBinds();
}