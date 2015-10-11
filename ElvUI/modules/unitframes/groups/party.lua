local E, L, V, P, G = unpack(select(2, ...));
local UF = E:GetModule("UnitFrames");

local _, ns = ...;
local ElvUF = ns.oUF;
assert(ElvUF, "ElvUI was unable to locate oUF.");
local tinsert = table.insert;

function UF:Construct_PartyFrames(unitGroup)
	self:SetScript("OnEnter", UnitFrame_OnEnter);
	self:SetScript("OnLeave", UnitFrame_OnLeave);
	
	self.RaisedElementParent = CreateFrame("Frame", nil, self);
	self.RaisedElementParent:SetFrameStrata("MEDIUM");
	self.RaisedElementParent:SetFrameLevel(self:GetFrameLevel() + 10);
	
	if(self.isChild) then
		self.Health = UF:Construct_HealthBar(self, true);
		
		self.Name = UF:Construct_NameText(self);
		self.originalParent = self:GetParent();
	else
		self:SetAttribute("initial-height", UF.db["units"]["party"].height);
		self:SetAttribute("initial-width", UF.db["units"]["party"].width);
		
		self.Health = UF:Construct_HealthBar(self, true, true, "RIGHT");
		self.Power = UF:Construct_PowerBar(self, true, true, "LEFT", false);
		self.Power.frequentUpdates = false;
		
		self.Name = UF:Construct_NameText(self);
		self.Portrait3D = UF:Construct_Portrait(self, "model");
		self.Portrait2D = UF:Construct_Portrait(self, "texture");
		self.Buffs = UF:Construct_Buffs(self);
		self.Debuffs = UF:Construct_Debuffs(self);
		self.AuraWatch = UF:Construct_AuraWatch(self);
		self.DebuffHighlight = UF:Construct_DebuffHighlight(self);
		self.LFDRole = UF:Construct_RoleIcon(self);
		self.TargetGlow = UF:Construct_TargetGlow(self);
		self.RaidRoleFramesAnchor = UF:Construct_RaidRoleFrames(self);
		tinsert(self.__elements, UF.UpdateTargetGlow);
		self:RegisterEvent("PLAYER_TARGET_CHANGED", UF.UpdateTargetGlow);
		self:RegisterEvent("PLAYER_ENTERING_WORLD", UF.UpdateTargetGlow);
		self:RegisterEvent("GROUP_ROSTER_UPDATE", UF.UpdateTargetGlow);
		self.Threat = UF:Construct_Threat(self);
		self.RaidIcon = UF:Construct_RaidIcon(self);
		self.ReadyCheck = UF:Construct_ReadyCheckIcon(self);
		
		self.customTexts = {};
	end
	
	self.Range = UF:Construct_Range(self);
	
	UF:Update_StatusBars();
	UF:Update_FontStrings();
	UF:Update_PartyFrames(self, UF.db["units"]["party"]);
	return self;
end

function UF:Update_PartyHeader(header, db)	
	header.db = db;
	
	local headerHolder = header:GetParent();
	headerHolder.db = db;
	
	if(not headerHolder.positioned) then
		headerHolder:ClearAllPoints();
		headerHolder:Point("BOTTOMLEFT", E.UIParent, "BOTTOMLEFT", 4, 195);
		
		E:CreateMover(headerHolder, headerHolder:GetName().."Mover", L["Party Frames"], nil, nil, nil, "ALL,PARTY,ARENA");
		headerHolder.positioned = true;

		headerHolder:RegisterEvent("PLAYER_ENTERING_WORLD");
		headerHolder:RegisterEvent("ZONE_CHANGED_NEW_AREA");
		headerHolder:SetScript("OnEvent", UF["PartySmartVisibility"]);
	end
	
	UF.PartySmartVisibility(headerHolder);
end

function UF:PartySmartVisibility(event)
	if(not self.db or (self.db and not self.db.enable) or (UF.db and not UF.db.smartRaidFilter) or self.isForced) then return; end
	local inInstance, instanceType = IsInInstance();
	if(event == "PLAYER_REGEN_ENABLED") then self:UnregisterEvent("PLAYER_REGEN_ENABLED"); end

	if(not InCombatLockdown()) then		
		if(inInstance and (instanceType == "raid" or instanceType == "pvp")) then
			UnregisterStateDriver(self, "visibility");
			self:Hide();
		elseif(self.db.visibility) then
			RegisterStateDriver(self, "visibility", self.db.visibility);
		end
	else
		self:RegisterEvent("PLAYER_REGEN_ENABLED");
	end
end

function UF:Update_PartyFrames(frame, db)
	frame.db = db;
	if(frame.Portrait) then
		frame.Portrait:Hide();
		frame.Portrait:ClearAllPoints();
		frame.Portrait.backdrop:Hide();
	end
	frame.Portrait = db.portrait.style == "2D" and frame.Portrait2D or frame.Portrait3D;
	local SPACING = E.Spacing;
	local BORDER = E.Border;
	local UNIT_WIDTH = db.width;
	local UNIT_HEIGHT = db.height;
	local SHADOW_SPACING = E.PixelMode and 3 or 4;
	local USE_POWERBAR = db.power.enable;
	local USE_MINI_POWERBAR = db.power.width == "spaced" and USE_POWERBAR;
	local USE_INSET_POWERBAR = db.power.width == "inset" and USE_POWERBAR;
	local USE_POWERBAR_OFFSET = db.power.offset ~= 0 and USE_POWERBAR;
	local POWERBAR_OFFSET = db.power.offset;
	local POWERBAR_HEIGHT = db.power.height;
	local POWERBAR_WIDTH = db.width - (BORDER*2);
	
	local USE_PORTRAIT = db.portrait.enable;
	local USE_PORTRAIT_OVERLAY = db.portrait.overlay and USE_PORTRAIT;
	local PORTRAIT_WIDTH = db.portrait.width;
	
	frame.db = db;
	frame.colors = ElvUF.colors;
	frame:RegisterForClicks(self.db.targetOnMouseDown and "AnyDown" or "AnyUp");
	
	do
		if(not USE_POWERBAR) then
			POWERBAR_HEIGHT = 0;
		end
		
		if(USE_PORTRAIT_OVERLAY or not USE_PORTRAIT) then
			PORTRAIT_WIDTH = 0;
		end
		
		if(USE_MINI_POWERBAR) then
			POWERBAR_WIDTH = POWERBAR_WIDTH / 2;
		end
	end
	
	if(frame.isChild) then
		local childDB = db.petsGroup;
		if(frame == _G[frame.originalParent:GetName().."Target"]) then
			childDB = db.targetsGroup;
		end
		
		if(not frame.originalParent.childList) then
			frame.originalParent.childList = {};
		end	
		frame.originalParent.childList[frame] = true;
		
		if(not InCombatLockdown()) then
			if(childDB.enable) then
				frame:SetParent(frame.originalParent);
				frame:Size(childDB.width, childDB.height);
				frame:ClearAllPoints();
				frame:Point(E.InversePoints[childDB.anchorPoint], frame.originalParent, childDB.anchorPoint, childDB.xOffset, childDB.yOffset);
			else
				frame:SetParent(E.HiddenFrame);
			end
		end
		
		do
			local health = frame.Health;
			health.Smooth = self.db.smoothbars;
			health.frequentUpdates = db.health.frequentUpdates;
			
			health.colorSmooth = nil;
			health.colorHealth = nil;
			health.colorClass = nil;
			health.colorReaction = nil;
			
			if(db.colorOverride == "FORCE_ON") then
				health.colorClass = true;
				health.colorReaction = true;
			elseif(db.colorOverride == "FORCE_OFF") then
				if(self.db["colors"].colorhealthbyvalue == true) then
					health.colorSmooth = true;
				else
					health.colorHealth = true;
				end
			else
				if(self.db["colors"].healthclass ~= true) then
					if(self.db["colors"].colorhealthbyvalue == true) then
						health.colorSmooth = true;
					else
						health.colorHealth = true;
					end
				else
					health.colorClass = true;
					health.colorReaction = true;
				end
				
				if(self.db["colors"].forcehealthreaction == true) then
					health.colorClass = false;
					health.colorReaction = true;
				end
			end
			
			health:ClearAllPoints();
			health:Point("TOPRIGHT", frame, "TOPRIGHT", -BORDER, -BORDER);
			health:Point("BOTTOMLEFT", frame, "BOTTOMLEFT", BORDER, BORDER);
		end
		
		do
			local name = frame.Name;
			name:ClearAllPoints();
			name:SetPoint("CENTER", frame.Health, "CENTER");
			frame:Tag(name, "[namecolor][name:short]");
		end			
	else
		frame:SetAttribute("initial-height", UNIT_HEIGHT);
		frame:SetAttribute("initial-width", UNIT_WIDTH);
		
		do
			local health = frame.Health;
			health.Smooth = self.db.smoothbars;
			
			local x, y = self:GetPositionOffset(db.health.position);
			health.value:ClearAllPoints();
			health.value:Point(db.health.position, health, db.health.position, x + db.health.xOffset, y + db.health.yOffset);
			frame:Tag(health.value, db.health.text_format);
			
			health.frequentUpdates = db.health.frequentUpdates;
			
			health.colorSmooth = nil;
			health.colorHealth = nil;
			health.colorClass = nil;
			health.colorReaction = nil;
			
			if(db.colorOverride == "FORCE_ON") then
				health.colorClass = true;
				health.colorReaction = true;
			elseif(db.colorOverride == "FORCE_OFF") then
				if(self.db["colors"].colorhealthbyvalue == true) then
					health.colorSmooth = true;
				else
					health.colorHealth = true;
				end
			else
				if(self.db["colors"].healthclass ~= true) then
					if(self.db["colors"].colorhealthbyvalue == true) then
						health.colorSmooth = true;
					else
						health.colorHealth = true;
					end
				else
					health.colorClass = true;
					health.colorReaction = true;
				end
			end
			
			health:ClearAllPoints();
			health:Point("TOPRIGHT", frame, "TOPRIGHT", -BORDER, -BORDER);
			if(USE_POWERBAR_OFFSET) then
				health:Point("BOTTOMLEFT", frame, "BOTTOMLEFT", BORDER+POWERBAR_OFFSET, BORDER+POWERBAR_OFFSET);
			elseif(USE_MINI_POWERBAR) then
				health:Point("BOTTOMLEFT", frame, "BOTTOMLEFT", BORDER, BORDER + (POWERBAR_HEIGHT/2));
			elseif(USE_INSET_POWERBAR) then
				health:Point("BOTTOMLEFT", frame, "BOTTOMLEFT", BORDER, BORDER);
			else
				health:Point("BOTTOMLEFT", frame, "BOTTOMLEFT", BORDER, (USE_POWERBAR and ((BORDER + SPACING)*2) or BORDER) + POWERBAR_HEIGHT);
			end
			
			health.bg:ClearAllPoints();
			if(not USE_PORTRAIT_OVERLAY) then
				health:Point("TOPRIGHT", -(PORTRAIT_WIDTH+BORDER), -BORDER);
				health.bg:SetParent(health);
				health.bg:SetAllPoints();
			else
				health.bg:Point("BOTTOMLEFT", health:GetStatusBarTexture(), "BOTTOMRIGHT");
				health.bg:Point("TOPRIGHT", health);
				health.bg:SetParent(frame.Portrait.overlay);
			end
			
			health:SetOrientation(db.health.orientation);
		end
		
		UF:UpdateNameSettings(frame);
		
		do
			local power = frame.Power;
			if(USE_POWERBAR) then
				frame:EnableElement("Power");
				power:Show();
				power.Smooth = self.db.smoothbars;
				
				local x, y = self:GetPositionOffset(db.power.position);
				power.value:ClearAllPoints();
				power.value:Point(db.power.position, frame.Health, db.power.position, x + db.power.xOffset, y + db.power.yOffset);		
				frame:Tag(power.value, db.power.text_format);
				
				power.colorClass = nil;
				power.colorReaction = nil;
				power.colorPower = nil;
				if(self.db["colors"].powerclass) then
					power.colorClass = true;
					power.colorReaction = true;
				else
					power.colorPower = true;
				end
				
				power:ClearAllPoints();
				if(USE_POWERBAR_OFFSET) then
					power:Point("TOPLEFT", frame.Health, "TOPLEFT", -POWERBAR_OFFSET, -POWERBAR_OFFSET);
					power:Point("BOTTOMRIGHT", frame.Health, "BOTTOMRIGHT", -POWERBAR_OFFSET, -POWERBAR_OFFSET);
					power:SetFrameStrata("LOW");
					power:SetFrameLevel(2);
				elseif(USE_MINI_POWERBAR) then
					power:Width(POWERBAR_WIDTH - BORDER*2);
					power:Height(POWERBAR_HEIGHT);
					power:Point("LEFT", frame, "BOTTOMLEFT", (BORDER*2 + 4), BORDER + (POWERBAR_HEIGHT/2));
					power:SetFrameStrata("MEDIUM");
					power:SetFrameLevel(frame:GetFrameLevel() + 3);
				elseif(USE_INSET_POWERBAR) then
					power:Height(POWERBAR_HEIGHT);
					power:Point("BOTTOMLEFT", frame.Health, "BOTTOMLEFT", BORDER + (BORDER*2), BORDER + (BORDER*2));
					power:Point("BOTTOMRIGHT", frame.Health, "BOTTOMRIGHT", -(BORDER + (BORDER*2)), BORDER + (BORDER*2));
					power:SetFrameStrata("MEDIUM");
					power:SetFrameLevel(frame:GetFrameLevel() + 3);
				else
					power:Point("TOPLEFT", frame.Health.backdrop, "BOTTOMLEFT", BORDER, -(E.PixelMode and 0 or (BORDER + SPACING)));
					power:Point("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -(BORDER + PORTRAIT_WIDTH), BORDER);
				end
			else
				frame:DisableElement("Power");
				power:Hide();
			end
		end
		
		do
			local portrait = frame.Portrait;
			if(USE_PORTRAIT) then
				if(not frame:IsElementEnabled("Portrait")) then
					frame:EnableElement("Portrait");
				end
				
				portrait:ClearAllPoints();
				if(USE_PORTRAIT_OVERLAY) then
					if(db.portrait.style == "3D") then
						portrait:SetFrameLevel(frame.Health:GetFrameLevel() + 1);
					end
					portrait:SetAllPoints(frame.Health);
					portrait:SetAlpha(0.3);
					portrait:Show();
					portrait.backdrop:Hide();
				else
					portrait:SetAlpha(1);
					portrait:Show();
					portrait.backdrop:Show();
					portrait.backdrop:ClearAllPoints();
					portrait.backdrop:SetPoint("TOPRIGHT", frame, "TOPRIGHT");
					if(db.portrait.style == "3D") then
						portrait:SetFrameLevel(frame:GetFrameLevel() + 5);
					end
					
					if(USE_MINI_POWERBAR or USE_POWERBAR_OFFSET or not USE_POWERBAR) then
						portrait.backdrop:Point("BOTTOMLEFT", frame.Health.backdrop, "BOTTOMRIGHT", E.PixelMode and -1 or SPACING, 0);
					else
						portrait.backdrop:Point("BOTTOMLEFT", frame.Power.backdrop, "BOTTOMRIGHT", E.PixelMode and -1 or SPACING, 0);
					end
					
					portrait:Point("BOTTOMLEFT", portrait.backdrop, "BOTTOMLEFT", BORDER, BORDER);
					portrait:Point("TOPRIGHT", portrait.backdrop, "TOPRIGHT", -BORDER, -BORDER);
				end
			else
				if(frame:IsElementEnabled("Portrait")) then
					frame:DisableElement("Portrait");
					portrait:Hide();
					portrait.backdrop:Hide();
				end
			end
		end
		
		do
			local threat = frame.Threat;
			if(db.threatStyle ~= "NONE" and db.threatStyle ~= nil) then
				if(not frame:IsElementEnabled("Threat")) then
					frame:EnableElement("Threat");
				end
				
				if(db.threatStyle == "GLOW") then
					threat:SetFrameStrata("BACKGROUND");
					threat.glow:ClearAllPoints();
					threat.glow:SetBackdropBorderColor(0, 0, 0, 0);
					threat.glow:Point("TOPLEFT", frame.Health.backdrop, "TOPLEFT", -SHADOW_SPACING, SHADOW_SPACING);
					threat.glow:Point("TOPRIGHT", frame.Health.backdrop, "TOPRIGHT", SHADOW_SPACING, SHADOW_SPACING);
					threat.glow:Point("BOTTOMLEFT", frame.Power.backdrop, "BOTTOMLEFT", -SHADOW_SPACING, -SHADOW_SPACING);
					threat.glow:Point("BOTTOMRIGHT", frame.Power.backdrop, "BOTTOMRIGHT", SHADOW_SPACING, -SHADOW_SPACING);
					
					if(USE_MINI_POWERBAR or USE_POWERBAR_OFFSET or USE_INSET_POWERBAR) then
						threat.glow:Point("BOTTOMLEFT", frame.Health.backdrop, "BOTTOMLEFT", -SHADOW_SPACING, -SHADOW_SPACING);
						threat.glow:Point("BOTTOMRIGHT", frame.Health.backdrop, "BOTTOMRIGHT", SHADOW_SPACING, -SHADOW_SPACING);
					end
					
					if(USE_PORTRAIT and not USE_PORTRAIT_OVERLAY) then
						threat.glow:Point("TOPRIGHT", frame.Portrait.backdrop, "TOPRIGHT", SHADOW_SPACING, -SHADOW_SPACING);
						threat.glow:Point("BOTTOMRIGHT", frame.Portrait.backdrop, "BOTTOMRIGHT", SHADOW_SPACING, -SHADOW_SPACING);
					end
				elseif(db.threatStyle == "ICONTOPLEFT" or db.threatStyle == "ICONTOPRIGHT" or db.threatStyle == "ICONBOTTOMLEFT" or db.threatStyle == "ICONBOTTOMRIGHT" or db.threatStyle == "ICONTOP" or db.threatStyle == "ICONBOTTOM" or db.threatStyle == "ICONLEFT" or db.threatStyle == "ICONRIGHT") then
					threat:SetFrameStrata("HIGH");
					local point = db.threatStyle;
					point = point:gsub("ICON", "");
					
					threat.texIcon:ClearAllPoints();
					threat.texIcon:SetPoint(point, frame.Health, point);
				end
			elseif(frame:IsElementEnabled("Threat")) then
				frame:DisableElement("Threat");
			end
		end
		
		do
			local tGlow = frame.TargetGlow;
			tGlow:ClearAllPoints();
			
			tGlow:Point("TOPLEFT", -SHADOW_SPACING, SHADOW_SPACING);
			tGlow:Point("TOPRIGHT", SHADOW_SPACING, SHADOW_SPACING);
			
			if(USE_MINI_POWERBAR) then
				tGlow:Point("BOTTOMLEFT", -SHADOW_SPACING, -SHADOW_SPACING + (POWERBAR_HEIGHT/2));
				tGlow:Point("BOTTOMRIGHT", SHADOW_SPACING, -SHADOW_SPACING + (POWERBAR_HEIGHT/2));		
			else
				tGlow:Point("BOTTOMLEFT", -SHADOW_SPACING, -SHADOW_SPACING);
				tGlow:Point("BOTTOMRIGHT", SHADOW_SPACING, -SHADOW_SPACING);
			end
			
			if(USE_POWERBAR_OFFSET) then
				tGlow:Point("TOPLEFT", -SHADOW_SPACING+POWERBAR_OFFSET, SHADOW_SPACING);
				tGlow:Point("TOPRIGHT", SHADOW_SPACING, SHADOW_SPACING);
				tGlow:Point("BOTTOMLEFT", -SHADOW_SPACING+POWERBAR_OFFSET, -SHADOW_SPACING+POWERBAR_OFFSET);
				tGlow:Point("BOTTOMRIGHT", SHADOW_SPACING, -SHADOW_SPACING+POWERBAR_OFFSET);
			end
		end
		
		do
			if(db.debuffs.enable or db.buffs.enable) then
				frame:EnableElement("Aura");
			else
				frame:DisableElement("Aura");
			end
			
			frame.Buffs:ClearAllPoints();
			frame.Debuffs:ClearAllPoints();
		end
		
		do
			local buffs = frame.Buffs;
			local rows = db.buffs.numrows;
			
			if(USE_POWERBAR_OFFSET) then
				buffs:SetWidth(UNIT_WIDTH - POWERBAR_OFFSET);
			else
				buffs:SetWidth(UNIT_WIDTH);
			end
			
			buffs.forceShow = frame.forceShowAuras;
			buffs.num = db.buffs.perrow * rows;
			buffs.size = db.buffs.sizeOverride ~= 0 and db.buffs.sizeOverride or ((((buffs:GetWidth() - (buffs.spacing*(buffs.num/rows - 1))) / buffs.num)) * rows);
			
			if(db.buffs.sizeOverride and db.buffs.sizeOverride > 0) then
				buffs:SetWidth(db.buffs.perrow * db.buffs.sizeOverride);
			end
			
			local x, y = E:GetXYOffset(db.buffs.anchorPoint);
			local attachTo = self:GetAuraAnchorFrame(frame, db.buffs.attachTo);
			
			buffs:Point(E.InversePoints[db.buffs.anchorPoint], attachTo, db.buffs.anchorPoint, x + db.buffs.xOffset, y + db.buffs.yOffset + (E.PixelMode and (db.buffs.anchorPoint:find("TOP") and -1 or 1) or 0));
			buffs:Height(buffs.size * rows);
			buffs["growth-y"] = db.buffs.anchorPoint:find("TOP") and "UP" or "DOWN";
			buffs["growth-x"] = db.buffs.anchorPoint == "LEFT" and "LEFT" or  db.buffs.anchorPoint == "RIGHT" and "RIGHT" or (db.buffs.anchorPoint:find("LEFT") and "RIGHT" or "LEFT");
			buffs["spacing-x"] = db.buffs.xSpacing;
			buffs["spacing-y"] = db.buffs.ySpacing;
			buffs.initialAnchor = E.InversePoints[db.buffs.anchorPoint];
			
			if(db.buffs.enable) then
				buffs:Show();
				UF:UpdateAuraIconSettings(buffs);
			else
				buffs:Hide();
			end
		end
		
		do
			local debuffs = frame.Debuffs;
			local rows = db.debuffs.numrows;
			
			if(USE_POWERBAR_OFFSET) then
				debuffs:SetWidth(UNIT_WIDTH - POWERBAR_OFFSET);
			else
				debuffs:SetWidth(UNIT_WIDTH);
			end
			
			debuffs.forceShow = frame.forceShowAuras;
			debuffs.num = db.debuffs.perrow * rows;
			debuffs.size = db.debuffs.sizeOverride ~= 0 and db.debuffs.sizeOverride or ((((debuffs:GetWidth() - (debuffs.spacing*(debuffs.num/rows - 1))) / debuffs.num)) * rows);
			
			if(db.debuffs.sizeOverride and db.debuffs.sizeOverride > 0) then
				debuffs:SetWidth(db.debuffs.perrow * db.debuffs.sizeOverride);
			end
			
			local x, y = E:GetXYOffset(db.debuffs.anchorPoint);
			local attachTo = self:GetAuraAnchorFrame(frame, db.debuffs.attachTo, db.debuffs.attachTo == "BUFFS" and db.buffs.attachTo == "DEBUFFS");
			
			debuffs:Point(E.InversePoints[db.debuffs.anchorPoint], attachTo, db.debuffs.anchorPoint, x + db.debuffs.xOffset, y + db.debuffs.yOffset);
			debuffs:Height(debuffs.size * rows);
			debuffs["growth-y"] = db.debuffs.anchorPoint:find("TOP") and "UP" or "DOWN";
			debuffs["growth-x"] = db.debuffs.anchorPoint == "LEFT" and "LEFT" or  db.debuffs.anchorPoint == "RIGHT" and "RIGHT" or (db.debuffs.anchorPoint:find("LEFT") and "RIGHT" or "LEFT");
			debuffs["spacing-x"] = db.debuffs.xSpacing;
			debuffs["spacing-y"] = db.debuffs.ySpacing;
			debuffs.initialAnchor = E.InversePoints[db.debuffs.anchorPoint];
			
			if(db.debuffs.enable) then
				debuffs:Show();
				UF:UpdateAuraIconSettings(debuffs);
			else
				debuffs:Hide();
			end
		end
		
		do
			local RI = frame.RaidIcon;
			if(db.raidicon.enable) then
				frame:EnableElement("RaidIcon");
				RI:Show();
				RI:Size(db.raidicon.size);
				
				local x, y = self:GetPositionOffset(db.raidicon.attachTo);
				RI:ClearAllPoints();
				RI:Point(db.raidicon.attachTo, frame, db.raidicon.attachTo, x + db.raidicon.xOffset, y + db.raidicon.yOffset);
			else
				frame:DisableElement("RaidIcon");
				RI:Hide();
			end
		end
		
		do
			local dbh = frame.DebuffHighlight;
			if(E.db.unitframe.debuffHighlighting) then
				frame:EnableElement("DebuffHighlight");
				frame.DebuffHighlightFilterTable = E.global.unitframe.DebuffHighlightColors;
				if(E.db.unitframe.debuffHighlighting == "GLOW") then
					frame.DebuffHighlightBackdrop = true;
					frame.DBHGlow:SetAllPoints(frame.Threat.glow);
				else
					frame.DebuffHighlightBackdrop = false;
				end
			else
				frame:DisableElement("DebuffHighlight");
			end
		end
		
		do
			local role = frame.LFDRole;
			if db.roleIcon.enable then
				frame:EnableElement("LFDRole");
				
				local x, y = self:GetPositionOffset(db.roleIcon.position, 1);
				role:ClearAllPoints();
				role:Point(db.roleIcon.position, frame.Health, db.roleIcon.position, x, y);
				role:Size(db.roleIcon.size);
			else
				frame:DisableElement("LFDRole");
				role:Hide();
			end
		end
		
		do
			local raidRoleFrameAnchor = frame.RaidRoleFramesAnchor;
			if(db.raidRoleIcons.enable) then
				raidRoleFrameAnchor:Show();
				frame:EnableElement("Leader");
				frame:EnableElement("MasterLooter");
				
				raidRoleFrameAnchor:ClearAllPoints();
				if(db.raidRoleIcons.position == "TOPLEFT") then
					raidRoleFrameAnchor:Point("LEFT", frame, "TOPLEFT", 2, 0);
				else
					raidRoleFrameAnchor:Point("RIGHT", frame, "TOPRIGHT", -2, 0);
				end
			else
				raidRoleFrameAnchor:Hide();
				frame:DisableElement("Leader");
				frame:DisableElement("MasterLooter");
			end
		end
		
		UF:UpdateAuraWatch(frame);
		
		frame:EnableElement("ReadyCheck");
		
		for objectName, object in pairs(frame.customTexts) do
			if((not db.customTexts) or (db.customTexts and not db.customTexts[objectName])) then
				object:Hide();
				frame.customTexts[objectName] = nil;
			end
		end
		
		if(db.customTexts) then
			local customFont = UF.LSM:Fetch("font", UF.db.font);
			for objectName, _ in pairs(db.customTexts) do
				if(not frame.customTexts[objectName]) then
					frame.customTexts[objectName] = frame.RaisedElementParent:CreateFontString(nil, "OVERLAY");
				end
				
				local objectDB = db.customTexts[objectName];
				if(objectDB.font) then
					customFont = UF.LSM:Fetch("font", objectDB.font);
				end
				
				frame.customTexts[objectName]:FontTemplate(customFont, objectDB.size or UF.db.fontSize, objectDB.fontOutline or UF.db.fontOutline);
				frame:Tag(frame.customTexts[objectName], objectDB.text_format or "");
				frame.customTexts[objectName]:SetJustifyH(objectDB.justifyH or "CENTER");
				frame.customTexts[objectName]:ClearAllPoints();
				frame.customTexts[objectName]:SetPoint(objectDB.justifyH or "CENTER", frame, objectDB.justifyH or "CENTER", objectDB.xOffset, objectDB.yOffset);
			end
		end
	end
	
	do
		local range = frame.Range;
		if(db.rangeCheck) then
			if(not frame:IsElementEnabled("Range")) then
				frame:EnableElement("Range");
			end
			
			range.outsideAlpha = E.db.unitframe.OORAlpha;
		else
			if(frame:IsElementEnabled("Range")) then
				frame:DisableElement("Range");
			end
		end
	end
	
	if(UF.db.colors.transparentHealth) then
		UF:ToggleTransparentStatusBar(true, frame.Health, frame.Health.bg);
	else
		UF:ToggleTransparentStatusBar(false, frame.Health, frame.Health.bg, (USE_PORTRAIT and USE_PORTRAIT_OVERLAY) ~= true);
	end
	
	if(frame.Power) then
		UF:ToggleTransparentStatusBar(UF.db.colors.transparentPower, frame.Power, frame.Power.bg);
	end
	
	frame:UpdateAllElements();
end

UF["headerstoload"]["party"] = { nil, "ELVUI_UNITPET, ELVUI_UNITTARGET" };