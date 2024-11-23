// Created by Driver

state("LegoHorizonAdventures-Win64-Shipping", "v1.2.0.0-Steam"){
    // GWorld, levelFname
    ulong levelFName : 0x891BE78, 0x18;
    // GWorld, Levels, Levels[1], WorldContainer, sceneFName
    ulong sceneFName : 0x891BE78, 0x170, 0x8, 0x20, 0x18;

    // GEngine, GameInstance, 0x108, 0x1D0, goldBricks
    int goldBricks : 0x8918FE8, 0x1088, 0x108, 0x1D0, 0x2A4;

    // Loading flags:
    // GEngine, GameInstance, 0x108, GlowMusicSubsystem, GlowMusicGameplayHandler, Flag
    bool isPaused : 0x8918FE8, 0x1088, 0x108, 0x368, 0x288, 0x1EE;
    bool isCinematic : 0x8918FE8, 0x1088, 0x108, 0x368, 0x288, 0x1EF;
    bool isConversation : 0x8918FE8, 0x1088, 0x108, 0x368, 0x288, 0x1F1;
    bool isLoading : 0x8918FE8, 0x1088, 0x108, 0x368, 0x288, 0x208;
    bool isFadeToBlack : 0x8918FE8, 0x1088, 0x108, 0x368, 0x288, 0x209;
    bool isBetweenWorlds : 0x8918FE8, 0x1088, 0x108, 0x368, 0x288, 0x20A;
    bool isWorldTransition : 0x8918FE8, 0x1088, 0x108, 0x368, 0x288, 0x20B;
}

// Script is executed
startup{
    // Object containing useful functions:
    vars.Funcs = new ExpandoObject();
    // Contains a list of checkpoints and coorelates with the split list:
    vars.checkpoints =  new Dictionary<string, ExpandoObject>();

    // Contains de autosplitter settings:
    dynamic[,] _settings = {
        // ID prefixes:
        // SSS: Start on scene start (currently not used)
        // SSE: Start on scene ending
        // WS: Split on world start (currently not used)
        // WE: Split on world ending
        // SS: Split on scene start (currently not used)
        // SE: Split on scene ending (currently not used)
        // GB: Split on gold brick
        // RB: Split on red brick (currently not used)
        // ID, Label, Tool tip, Parent ID, Default setting?
        {"SSE_StarterFrontendMap", "Start", "Starts the autosplitter automatically after starting a playthrough", null, true},
        {"m_quests", "Any%", null, null, true},
            {"WE_Prologue_P", "Prologue", "After completing the prologue", "m_quests", true},
            {"ch1", "Ch. 1- Rescuing the Nora", null, "m_quests", true},
                {"GB_B1_Room_003_Lighting_Day", "Into the woods", "", "ch1", true},
                {"GB_SR_B1_Tallneck_Exit_Lighting_Morning_Tallneck_Exit", "Head in the clouds", "", "ch1", true},
                {"GB_B1_Room_010_Lighting_Day_Forest", "Cult following", "", "ch1", true},
                {"GB_B1_Room_006_Lighting_Evening_Forest", "Face to the sun", "", "ch1", true},
                {"GB_TreasureRoom_01_Lighting_Evening", "A strange detour", "", "ch1", true},
                {"GB_B1_Room_004_Lighting_Night", "A girl and her destiny", "", "ch1", true},
            {"ch2", "Ch. 2 - Thunder in the Mountains", null, "m_quests", true},
                {"GB_B2_Room_001_Lighting_Day_Mountain", "The cold calling", "", "ch2", true},
                {"GB_B2_TreasureRoom_001_Lighting_Night_Mountain", "The hills are alive", "", "ch2", true},
                {"GB_B2_Room_003_Lighting_Day_Mountain", "Frosted peaks", "", "ch2", true},
                {"GB_B2_TreasureRoom_001_Lighting_Day_Mountain", "The shivering summit", "", "ch2", true},
                {"GB_B2_Room_007_Lighting_Evening_Mountain", "A tower achievement", "", "ch2", true},
                {"GB_Cau_Boss_Lighting", "The belly of the beast", "", "ch2", true},
            {"ch3", "Ch. 3 - Desperately Seeking Sawtooths", null, "m_quests", true},
                {"GB_B3_Room_001_Lighting_Morning_Jungle", "Lair of the tree haters", "", "ch3", true},
                {"GB_SR_B3_Tallneck_01_Exit_Lighting_Day_Jungle", "Digging up secrets", "", "ch3", true},
                {"GB_B3_Room_006_Lighting_Evening_Jungle", "Home cooking", "", "ch3", true},
                {"GB_B3_Room_009_Lighting_Night_Jungle", "Legend of the mithyc tale", "", "ch3", true},
                {"GB_B3_Boss_Room_BiomassFacility_Lighting", "Instructions not required", "", "ch3", true},
            {"ch4", "Ch. 4 - Drawing Out Helis", null, "m_quests", true},
                {"GB_B4_Room_002_Lighting_Day_Desert", "The desert flower", "", "ch4", true},
                {"GB_B4_Room_004_Lighting_Day_Desert", "Flavors of a lost world", "", "ch4", true},
                {"GB_SR_B4_Tallneck_01_Exit_Lighting_Day_Desert", "Midday at the oasis", "", "ch4", true},
                {"GB_B4_Room_007_Lighting_Night_Desert", "We can be heroes", "", "ch4", true},
                {"GB_B4_Room_005_Lighting_Evening_Desert", "Sundown showdown", "", "ch4", true},
                {"GB_B5_Boss_Room_001_Lighting_Destruction_Jungle_Hell", "The final battle", "", "ch4", true}
    };

    // Calculates the hash of a given module.
    // Taken from ISO2768mK's Horizon Forbidden West load remover:
    vars.Funcs.hashModule = (Func<ProcessModuleWow64Safe, string>)((module) => {
        byte[]  hashBytes = new byte[0];
        using (var sha256Object = System.Security.Cryptography.SHA256.Create())
        {
            using (var binary = File.Open(module.FileName, FileMode.Open, FileAccess.Read, FileShare.ReadWrite))
            {
                hashBytes = sha256Object.ComputeHash(binary);
            }
        }
        var hexHashString = hashBytes.Select(x => x.ToString("X2")).Aggregate((a, b) => a + b);
        return hexHashString;
    });

    // Default variables (Patch 1.2.0.0 Steam version):
    version = "v1.2.0.0-Steam";
    vars.FNamePoolOffset = 0x86F9500;
    // Determines the running game version and initialize variables acordingly:
    vars.Funcs.setGameVersion = (Action<string>)((hash) => {
        // TODO: add EpicGames version:
        if(hash == "<EPIC_GAMES_HASH_STRING>"){
            // Update variables
        // Patch 1.2.0.0 Steam:
        }else if(hash == "5CD97AF9CCAE47FB6A4534DEC00BBD6FE8F9FB1AD752BB6571F364C1E65CAEDC"){
            // Don't do anything, the default variables are the Steam ones...
            print("Detected game version: 1.2.0.0-Steam");
        }
        else{
            // If no version was identified, show a warning message:
            MessageBox.Show(
                "The Autosplitter could not identify the game version, the default version was set to " + version + ".\nIf this is not the version of your game, the Autosplitter might not work properly.",
                "HFW Autosplitter",
                MessageBoxButtons.OK,
                MessageBoxIcon.Warning
            );
        }
    });

    // Initialize autosplit settings
    dynamic tmp = null;
    for (int i = 0; i < _settings.GetLength(0); i++){
        tmp = new ExpandoObject();
        tmp.reachedBefore = false;
        // Autosplitter settings entry:
        // settings.Add(id, default_value = true, description = null, parent = null)
        settings.Add(_settings[i, 0], _settings[i, 4], _settings[i, 1], _settings[i, 3]);
        // Tool tip message (if available)
        if(_settings[i, 2] != null){
            settings.SetToolTip(_settings[i, 0], _settings[i, 2]);
        }
        vars.checkpoints.Add(_settings[i, 0], tmp);
    }
} // startup ends

init{
    // Gets the running game module hash:
    var moduleHash = vars.Funcs.hashModule(modules.First());
    // print(moduleHash);

    // Initialize variables acording to the running version:
    vars.Funcs.setGameVersion(moduleHash);

    // Determines if the game is currently loading:
    vars.Funcs.isLoading = (Func<bool>)(() => {
        // Comment out unwanted flags:
        return
            // current.isPaused || // Pause menu (the one when you press ESC)
            // current.isCinematic || // Cinematics
            // current.isConversation || // Conversations
            current.isLoading || // General game loading
            // current.isFadeToBlack || // That brief moment when the screen fades in or out
            current.isBetweenWorlds || // Scene and world transitions
            current.isWorldTransition; // World transitions
            // Title screen:
            // vars.Funcs.FNameToString(current.levelFName) == "StarterFrontendMap";
    });

    // Determines if it is time to split:
    vars.Funcs.isSplit = (Func<string, bool>)((splitName) => {
        if(
            // Splits only if the user has enabled this split in the autosplitter settings:
            settings[splitName] &&
            // Splits only once per checkpoint:
            !vars.checkpoints[splitName].reachedBefore
        ){ 
            vars.checkpoints[splitName].reachedBefore = true;
            print("SPLIT: " + splitName);
            return true;
        }
        else{
            return false;
        }
    });

    // Unreal Engine's structures ********************************************
    IntPtr FNamePool = modules.First().BaseAddress + vars.FNamePoolOffset;
    // ***********************************************************************

    // Takes an FName object and returns the asociated string.
    // Based on TheDementedSalad's Silent Hill 2 remake autosplitter:
    vars.Funcs.FNameToString = (Func<ulong, string>)(fName => {
		var nameIdx  = (fName & 0x000000000000FFFF) >> 0x00;
		var chunkIdx = (fName & 0x00000000FFFF0000) >> 0x10;

        IntPtr chunk = memory.ReadValue<IntPtr>(FNamePool + 0x10 + (int)chunkIdx * 0x8);
		IntPtr entry = chunk + (int)nameIdx * sizeof(short);

		int length = memory.ReadValue<short>(entry) >> 6;
        string name = memory.ReadString(entry + sizeof(short), length);

		return name;
	});
} // init ends

update{
    // print(vars.Funcs.FNameToString(current.levelFName));
    // print(vars.Funcs.FNameToString(current.sceneFName));
}

isLoading{
    return vars.Funcs.isLoading();
}

start{
    if(old.levelFName != current.levelFName){
        var currentWorldName = vars.Funcs.FNameToString(current.levelFName);
        var oldWorldName = vars.Funcs.FNameToString(old.levelFName);
        print("\n\nWorld changed: " + currentWorldName);
        // World ending starting points:
        if(vars.Funcs.isSplit("SSE_" + oldWorldName)){
            return true;
        }
    }
}

split{
    // Checks if the timer is actually running:
    if (timer.CurrentPhase == TimerPhase.Running){
        var currentSceneName = vars.Funcs.FNameToString(current.sceneFName);
        // Gold brick splits:
        if(current.goldBricks > old.goldBricks){
            if(vars.Funcs.isSplit("GB_" + currentSceneName)){
                return true;
            }
        }
        // World splits:
        if(old.levelFName != current.levelFName){
            var currentWorldName = vars.Funcs.FNameToString(current.levelFName);
            var oldWorldName = vars.Funcs.FNameToString(old.levelFName);
            print("\n\nWorld changed: " + currentWorldName);
            // World ending splits:
            if(vars.Funcs.isSplit("WE_" + oldWorldName)){
                return true;
            }
            // World start splits:
            if(vars.Funcs.isSplit("WS_" + currentWorldName)){
                return true;
            }
        }
    }
}

onReset{
    foreach (var checkpoint in vars.checkpoints){
        checkpoint.Value.reachedBefore = false;
    }
}

// Clean up to pre-init state when game process is closed
exit {
    foreach (var checkpoint in vars.checkpoints){
        checkpoint.Value.reachedBefore = false;
    }
}
// exit END
