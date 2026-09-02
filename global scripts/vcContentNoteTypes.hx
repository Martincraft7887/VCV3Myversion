function registerNoteTypes() {
	
	noteTypeData.set("RevPunch", {skin: "RevPunchAlt", mustPress: true, health: 1.5, echo: "Wiik3Rev", rotate: true, animSuffix: "-dodge", effect: "blur"});
	noteTypeData.set("RevSword", {skin: "RevSword", mustPress: true, health: 0.5, echo: "Wiik4Rev", animSuffix: "-dodge", effect: "maxHealth", offsetsY: [-10, -10, -10, -10], offsetsYDS: [-10, -10, -10, -10]});

	
	noteTypeData.set("REJECTED_NOTES", {skin: "REJECTED_NOTES", mustPress: false, health: 2.0, echo: "", offsetsY: [-145, -145, -145, -145], offsetsYDS: [-20, -20, -20, -20]});

	
	noteTypeData.set("BoxingMatchPunch", {
		skin: "BoxingMatchPunch",
		mustPress: true,
		health: 0.75,
		echo: "Wiik2",
		animSuffix: "-dodge",
		effect: "blurSmall"
	});

	var wiik3PunchData = {
		skin: "Wiik3Punch",
		skinalt: "Wiik3Punch-Alt",
		mustPress: true,
		health: 1.0,
		echo: "Wiik3Purple",
		animSuffix: "-dodge",
		effect: "blur"
	};
	noteTypeData.set("Wiik3Punch", wiik3PunchData);

	noteTypeData.set("Wiik4Sword", {
		skin: "Wiik4Sword",
		mustPress: true,
		health: 0.35,
		echo: "Wiik4Purple",
		animSuffix: "-dodge",
		effect: "maxHealth",
		offsetsY: [-10, -10, -10, -10],
		offsetsYDS: [-10, -10, -10, -10]
	});

	noteTypeData.set("VoiidBullet", {
		skin: "VoiidBullet",
		mustPress: true,
		health: 0.75,
		echo: "",
		animSuffix: "-dodge",
		effect: "drain",
		bullet: true,
		offsetsX: [-25, -4, -7, 5],
		offsetsY: [0, 0, -32, 0],
		offsetsYDS: [-40, -30, 0, -40]
	});

	noteTypeData.set("ParryNote", {
		skin: "ParryNote",
		mustPress: true,
		health: 3,
		echo: "",
		animSuffix: "-dodge",
		offsetsY: [-165, -165, -165, -165],
		offsetsYDS: [-40, -40, -40, -40],
		flipUS: true,
		parry: true
	});

	
	noteTypeData.set("GreedPunch", {skin: "GreedPunch", skinalt: "GreedNotes", mustPress: true, health: 0.75, echo: "GreedBlast", animSuffix: "-dodge", effect: "blurSmall", altoffsetsX: [-75, -75, -75, -75], altoffsetsY: [-145, -145, -145, -145], altoffsetsYDS: [-145, -145, -145, -145]});
	noteTypeData.set("SwordGreen", {skin: "SwordGreen", mustPress: true, health: 0.35, echo: "Wiik4Purple", animSuffix: "-dodge", effect: "maxHealth", offsetsY: [-10, -10, -10, -10], offsetsYDS: [-10, -10, -10, -10]});

	
	noteTypeData.set("RejectedPunch", {skin: "RejectedPunch", mustPress: true, health: 1.0, echo: "Wiik3Purple", animSuffix: "-dodge", effect: "blur"});
	noteTypeData.set("RejectedSword", {skin: "RejectedSword", mustPress: true, health: 0.35, echo: "Wiik4Purple", animSuffix: "-dodge", effect: "maxHealth", offsetsY: [-10, -10, -10, -10], offsetsYDS: [-10, -10, -10, -10]});
	noteTypeData.set("RejectedBullet", {skin: "RejectedBullet", mustPress: true, health: 0.4, echo: "Wiik2", animSuffix: "-dodge", effect: "drain", offsetsX: [-25, -4, -7, 5], offsetsY: [0, 0, -32, 0], offsetsYDS: [-40, -30, 0, -40]});
	noteTypeData.set("REJECTED_VIP_NOTES", {skin: "REJECTED_NOTES", mustPress: false, health: 2.0, echo: "", offsetX: 0, offsetY: 0, offsetsY: [-145, -145, -145, -145], offsetsYDS: [-20, -20, -20, -20]});
	noteTypeData.set("AntarkhNotes", {skin: "AntarkhNotes", mustPress: true, health: 0.15, echo: "", offsetX: 0, offsetY: 0, offsetsY: [-145, -145, -145, -145], offsetsYDS: [-20, -20, -20, -20]});

	disableScript();
}