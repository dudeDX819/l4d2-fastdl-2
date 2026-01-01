//------------------------------------------------------------
// Shared Common Infected Animation Fix
// Fixes A-posing / frozen commons after model swap
// Activates ONLY if ScriptScope flag is present
//------------------------------------------------------------

nanas_common_anim_fix3 <-
{
	//--------------------------------------------------------
	// CONFIG
	//--------------------------------------------------------
	THINK_INTERVAL = 0.05      // fast but cheap
	STUMBLE_FLAG   = 33554432  // DMG_STUMBLE
	BULLET_FLAG    = 2         // DMG_BULLET

	//--------------------------------------------------------
	function OnGameEvent_round_start(params)
	{
		SpawnEntityFromTable("logic_timer",
		{
			RefireTime = THINK_INTERVAL,
			StartDisabled = 0,
			OnTimer = "!self,runscriptcode,DirectorScript.nanas_common_anim_fix3.Think()"
		});
	}

	//--------------------------------------------------------
	function Think()
	{
		local ent = null;

		while (ent = Entities.FindByClassname(ent, "infected"))
		{
			if (!ent || !ent.IsValid() || ent.GetHealth() <= 0)
				continue;

			if (!ent.ValidateScriptScope())
				continue;

			local s = ent.GetScriptScope();

			//------------------------------------------------
			// REQUIRED FLAG (set by other mods)
			//------------------------------------------------
			if (!("IsPrisoner" in s))
				continue;

			//------------------------------------------------
			// Prevent repeated application
			//------------------------------------------------
			if ("AnimFixApplied" in s)
				continue;

			s.AnimFixApplied <- true;

			//------------------------------------------------
			// Delay slightly so model + netprops settle
			//------------------------------------------------
			EntFire(
				"worldspawn",
				"RunScriptCode",
				"DirectorScript.nanas_common_anim_fix3.ApplyFix(" + ent.GetEntityIndex() + ")",
				0.5,
				null
			);
		}
	}

	//--------------------------------------------------------
	function ApplyFix(idx)
	{
		local ent = EntIndexToHScript(idx);
		if (!ent || !ent.IsValid() || ent.GetHealth() <= 0)
			return;

		//----------------------------------------------------
		// 1) Fake stumble (break animation lock)
		//----------------------------------------------------
		ent.TakeDamage(0.0, STUMBLE_FLAG, null);

		//----------------------------------------------------
		// 2) Bullet nudge (forces anim state update)
		//----------------------------------------------------
		ent.TakeDamage(1, BULLET_FLAG, null);

		//----------------------------------------------------
		// 3) Force animation cycle forward
		//----------------------------------------------------
		try
		{
			NetProps.SetPropFloat(ent, "m_flCycle", 1.0);
		}
		catch (e) {}

		//----------------------------------------------------
		// 4) Force running gesture
		//----------------------------------------------------
		try
		{
			NetProps.SetPropIntArray(
				ent,
				"m_NetGestureSequence",
				ent.LookupSequence("ACT_RUN"),
				6
			);

			NetProps.SetPropIntArray(
				ent,
				"m_NetGestureActivity",
				ent.LookupActivity("ACT_RUN"),
				6
			);

			NetProps.SetPropFloatArray(
				ent,
				"m_NetGestureStartTime",
				Time(),
				6
			);
		}
		catch (e) {}
	}
}

//------------------------------------------------------------
// REGISTER
//------------------------------------------------------------
DirectorScript.nanas_common_anim_fix3 <- nanas_common_anim_fix3;
__CollectGameEventCallbacks(nanas_common_anim_fix3);
