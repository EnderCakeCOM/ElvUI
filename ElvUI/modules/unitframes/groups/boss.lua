local E, L, V, P, G = unpack(select(2, ...));
local UF = E:GetModule('UnitFrames');

local _, ns = ...;
local ElvUF = ns.oUF;
assert(ElvUF, 'ElvUI was unable to locate oUF.');

local BossHeader = CreateFrame('Frame', 'BossHeader', UIParent);

function UF:Construct_BossFrames(frame)	
	frame.Health = self:Construct_HealthBar(frame, true, true, 'RIGHT'); -- Здоровье
	frame.Power = self:Construct_PowerBar(frame, true, true, 'LEFT', false); -- Мана
	frame.Name = self:Construct_NameText(frame); -- Имя
	frame.Portrait3D = self:Construct_Portrait(frame, 'model'); -- 2D портерт
	frame.Portrait2D = self:Construct_Portrait(frame, 'texture'); -- 3D портрет
	frame.Buffs = self:Construct_Buffs(frame); -- Баффы
	frame.Debuffs = self:Construct_Debuffs(frame); -- Дебаффы
	frame.Castbar = self:Construct_Castbar(frame, 'RIGHT'); -- Полоса заклинаний
	frame.RaidIcon = UF:Construct_RaidIcon(frame); -- Рейдовая иконка
	frame.Range = UF:Construct_Range(frame); -- Проверка дистанции
	frame:SetAttribute('type2', 'focus');
	
	frame.TargetGlow = UF:Construct_TargetGlow(frame)
	tinsert(frame.__elements, UF.UpdateTargetGlow)
	frame:RegisterEvent('PLAYER_TARGET_CHANGED', UF.UpdateTargetGlow)
	frame:RegisterEvent('PLAYER_ENTERING_WORLD', UF.UpdateTargetGlow)
	frame:RegisterEvent('GROUP_ROSTER_UPDATE', UF.UpdateTargetGlow)
	
	BossHeader:Point('BOTTOMRIGHT', E.UIParent, 'RIGHT', -105, -165); -- Позиция 
	E:CreateMover(BossHeader, BossHeader:GetName()..'Mover', L['Boss Frames'], nil, nil, nil, 'ALL,PARTY,RAID10,RAID25,RAID40');
end

function UF:Update_BossFrames(frame, db)
	frame.db = db
	
	if frame.Portrait then
		frame.Portrait:Hide()
		frame.Portrait:ClearAllPoints()
		frame.Portrait.backdrop:Hide()
	end
	frame.Portrait = db.portrait.style == '2D' and frame.Portrait2D or frame.Portrait3D
	frame:RegisterForClicks(self.db.targetOnMouseDown and 'AnyDown' or 'AnyUp')
	local BORDER = E.Border;
	local SPACING = E.Spacing;
	local INDEX = frame.index
	local UNIT_WIDTH = db.width
	local UNIT_HEIGHT = db.height
	local SHADOW_SPACING = E.PixelMode and 3 or 4
	local USE_POWERBAR = db.power.enable
	local USE_MINI_POWERBAR = db.power.width == 'spaced' and USE_POWERBAR
	local USE_INSET_POWERBAR = db.power.width == 'inset' and USE_POWERBAR
	local USE_POWERBAR_OFFSET = db.power.offset ~= 0 and USE_POWERBAR
	local POWERBAR_OFFSET = db.power.offset
	local POWERBAR_HEIGHT = db.power.height
	local POWERBAR_WIDTH = db.width - (BORDER*2)
		
	local USE_PORTRAIT = db.portrait.enable
	local USE_PORTRAIT_OVERLAY = db.portrait.overlay and USE_PORTRAIT
	local PORTRAIT_WIDTH = db.portrait.width
	
	local unit = self.unit
	
	frame.colors = ElvUF.colors
	frame:Size(UNIT_WIDTH, UNIT_HEIGHT)
	
	--Adjust some variables
	do
		if not USE_POWERBAR then
			POWERBAR_HEIGHT = 0
		end	
	
		if USE_PORTRAIT_OVERLAY or not USE_PORTRAIT then
			PORTRAIT_WIDTH = 0
		end

		if USE_MINI_POWERBAR then
			POWERBAR_WIDTH = POWERBAR_WIDTH / 2
		end
	end
	
	do -- Входящие исцеление
		frame.HealCommBar = CreateFrame('StatusBar', nil, frame.Health)
		
		local c = UF.db.colors.healPrediction
		
		if db.healPrediction then
			if not frame:IsElementEnabled('HealComm4') then
				frame:EnableElement('HealComm4')
			end
			
			frame.HealCommBar:SetStatusBarTexture(E['media'].blankTex)
			frame.HealCommBar:SetFrameLevel(frame.Health:GetFrameLevel())
			
			if not USE_PORTRAIT_OVERLAY then
				frame.HealCommBar:SetParent(frame.Health)
			else	
				frame.HealCommBar:SetParent(frame.Portrait.overlay)
			end
			
			frame.HealCommBar:SetStatusBarColor(c.personal.r, c.personal.g, c.personal.b, c.personal.a)
		else
			if frame:IsElementEnabled('HealComm4') then
				frame:DisableElement('HealComm4')
			end
		end
	end
	
	do -- Здоровье
		local health = frame.Health
		health.Smooth = self.db.smoothbars

		local x, y = self:GetPositionOffset(db.health.position) -- Текст
		health.value:ClearAllPoints()
		health.value:Point(db.health.position, health, db.health.position, x + db.health.xOffset, y + db.health.yOffset)
		frame:Tag(health.value, db.health.text_format)
		
		health.colorSmooth = nil -- Цвет
		health.colorHealth = nil
		health.colorClass = nil
		health.colorReaction = nil
		if self.db['colors'].healthclass ~= true then
			if self.db['colors'].colorhealthbyvalue == true then
				health.colorSmooth = true
			else
				health.colorHealth = true
			end		
		else
			health.colorClass = true
			health.colorReaction = true
		end	
		
		health:ClearAllPoints() -- Позиция
		health:Point('TOPRIGHT', frame, 'TOPRIGHT', -BORDER, -BORDER)
		if USE_POWERBAR_OFFSET then			
			health:Point('BOTTOMLEFT', frame, 'BOTTOMLEFT', BORDER+POWERBAR_OFFSET, BORDER+POWERBAR_OFFSET)
		elseif USE_MINI_POWERBAR then
			health:Point('BOTTOMLEFT', frame, 'BOTTOMLEFT', BORDER, BORDER + (POWERBAR_HEIGHT/2))
		elseif USE_INSET_POWERBAR then
			health:Point('BOTTOMLEFT', frame, 'BOTTOMLEFT', BORDER, BORDER)	
		else
			health:Point('BOTTOMLEFT', frame, 'BOTTOMLEFT', BORDER, BORDER + POWERBAR_HEIGHT)
		end
		
		health.bg:ClearAllPoints()
		if not USE_PORTRAIT_OVERLAY then
			health:Point('TOPRIGHT', -(PORTRAIT_WIDTH+BORDER), -BORDER)
			health.bg:SetParent(health)
			health.bg:SetAllPoints()
		else
			health.bg:Point('BOTTOMLEFT', health:GetStatusBarTexture(), 'BOTTOMRIGHT')
			health.bg:Point('TOPRIGHT', health)		
			health.bg:SetParent(frame.Portrait.overlay)	
		end
	end
	
	UF:UpdateNameSettings(frame) -- Имя
	
	do -- Мана
		local power = frame.Power
		
		if USE_POWERBAR then
			if not frame:IsElementEnabled('Power') then
				frame:EnableElement('Power')
				power:Show()
			end				
			power.Smooth = self.db.smoothbars
			
			local x, y = self:GetPositionOffset(db.power.position) -- Текст
			power.value:ClearAllPoints()
			power.value:Point(db.power.position, frame.Health, db.power.position, x + db.power.xOffset, y + db.power.yOffset)		
			frame:Tag(power.value, db.power.text_format)
			
			power.colorClass = nil -- Цвет
			power.colorReaction = nil	
			power.colorPower = nil
			if self.db['colors'].powerclass then
				power.colorClass = true
				power.colorReaction = true
			else
				power.colorPower = true
			end		
			
			power:ClearAllPoints() -- Позиция
			if USE_POWERBAR_OFFSET then
				power:Point('TOPLEFT', frame.Health, 'TOPLEFT', -POWERBAR_OFFSET, -POWERBAR_OFFSET)
				power:Point('BOTTOMRIGHT', frame.Health, 'BOTTOMRIGHT', -POWERBAR_OFFSET, -POWERBAR_OFFSET)
				power:SetFrameStrata("LOW");
				power:SetFrameLevel(2);
			elseif USE_MINI_POWERBAR then
				power:Width(POWERBAR_WIDTH - BORDER*2)
				power:Height(POWERBAR_HEIGHT - BORDER*2)
				power:Point('LEFT', frame, 'BOTTOMLEFT', (BORDER*2 + 4), BORDER + (POWERBAR_HEIGHT/2))
				power:SetFrameStrata("MEDIUM");
				power:SetFrameLevel(frame:GetFrameLevel() + 3);
			elseif USE_INSET_POWERBAR then
				power:Height(POWERBAR_HEIGHT - BORDER*2)
				power:Point('BOTTOMLEFT', frame.Health, 'BOTTOMLEFT', BORDER + (BORDER*2), BORDER + (BORDER*2))
				power:Point('BOTTOMRIGHT', frame.Health, 'BOTTOMRIGHT', -(BORDER + (BORDER*2)), BORDER + (BORDER*2))
				power:SetFrameStrata("MEDIUM");
				power:SetFrameLevel(frame:GetFrameLevel() + 3);
			else
				power:Point('TOPLEFT', frame.Health.backdrop, 'BOTTOMLEFT', BORDER, -(E.PixelMode and 0 or (BORDER + SPACING)))
				power:Point('BOTTOMRIGHT', frame, 'BOTTOMRIGHT', -(BORDER + PORTRAIT_WIDTH), BORDER)
			end
		elseif frame:IsElementEnabled('Power') then
			frame:DisableElement('Power')
			power:Hide()
		end
	end
	
	do -- Портрет
		local portrait = frame.Portrait
		
		if USE_PORTRAIT then -- Позиция
			if not frame:IsElementEnabled('Portrait') then
				frame:EnableElement('Portrait')
			end
			
			portrait:ClearAllPoints()
			
			if USE_PORTRAIT_OVERLAY then
				if db.portrait.style == '3D' then
					portrait:SetFrameLevel(frame.Health:GetFrameLevel() + 1)
				end
				portrait:SetAllPoints(frame.Health)
				portrait:SetAlpha(0.3)
				portrait:Show()		
				portrait.backdrop:Hide()
			else
				portrait:SetAlpha(1)
				portrait:Show()
				portrait.backdrop:Show()
				portrait.backdrop:ClearAllPoints()
				portrait.backdrop:SetPoint('TOPRIGHT', frame, 'TOPRIGHT')
				if db.portrait.style == '3D' then
					portrait:SetFrameLevel(frame:GetFrameLevel() + 5)
				end								
						
				if USE_MINI_POWERBAR or USE_POWERBAR_OFFSET or not USE_POWERBAR then
					portrait.backdrop:Point('BOTTOMLEFT', frame.Health.backdrop, 'BOTTOMRIGHT', E.PixelMode and -1 or SPACING, 0)
				else
					portrait.backdrop:Point('BOTTOMLEFT', frame.Power.backdrop, 'BOTTOMRIGHT', E.PixelMode and -1 or SPACING, 0)
				end	
							
				portrait:Point('BOTTOMLEFT', portrait.backdrop, 'BOTTOMLEFT', BORDER, BORDER)		
				portrait:Point('TOPRIGHT', portrait.backdrop, 'TOPRIGHT', -BORDER, -BORDER)				
			end
		else
			if frame:IsElementEnabled('Portrait') then
				frame:DisableElement('Portrait')
				portrait:Hide()
				portrait.backdrop:Hide()
			end		
		end
	end
	
	do
		local tGlow = frame.TargetGlow;
		tGlow:ClearAllPoints();
		
		tGlow:Point("TOPLEFT", -SHADOW_SPACING, SHADOW_SPACING);
		tGlow:Point("TOPRIGHT", SHADOW_SPACING, SHADOW_SPACING);
		
		if USE_MINI_POWERBAR then
			tGlow:Point("BOTTOMLEFT", -SHADOW_SPACING, -SHADOW_SPACING + (POWERBAR_HEIGHT/2));
			tGlow:Point("BOTTOMRIGHT", SHADOW_SPACING, -SHADOW_SPACING + (POWERBAR_HEIGHT/2));
		else
			tGlow:Point("BOTTOMLEFT", -SHADOW_SPACING, -SHADOW_SPACING);
			tGlow:Point("BOTTOMRIGHT", SHADOW_SPACING, -SHADOW_SPACING);
		end
		
		if USE_POWERBAR_OFFSET then
			tGlow:Point("TOPLEFT", -SHADOW_SPACING+POWERBAR_OFFSET, SHADOW_SPACING);
			tGlow:Point("TOPRIGHT", SHADOW_SPACING, SHADOW_SPACING);
			tGlow:Point("BOTTOMLEFT", -SHADOW_SPACING+POWERBAR_OFFSET, -SHADOW_SPACING+POWERBAR_OFFSET);
			tGlow:Point("BOTTOMRIGHT", SHADOW_SPACING, -SHADOW_SPACING+POWERBAR_OFFSET);
		end
	end
	
	do
		if db.debuffs.enable or db.buffs.enable then
			if not frame:IsElementEnabled('Aura') then
				frame:EnableElement('Aura')
			end	
		else
			if frame:IsElementEnabled('Aura') then
				frame:DisableElement('Aura')
			end			
		end
		
		frame.Buffs:ClearAllPoints()
		frame.Debuffs:ClearAllPoints()
	end
	
	do -- Баффы
		local buffs = frame.Buffs
		local rows = db.buffs.numrows
		
		if USE_POWERBAR_OFFSET then
			buffs:SetWidth(UNIT_WIDTH - POWERBAR_OFFSET)
		else
			buffs:SetWidth(UNIT_WIDTH)
		end
		
		buffs.forceShow = frame.forceShowAuras
		buffs.num = db.buffs.perrow * rows
		buffs.size = db.buffs.sizeOverride ~= 0 and db.buffs.sizeOverride or ((((buffs:GetWidth() - (buffs.spacing*(buffs.num/rows - 1))) / buffs.num)) * rows)
		
		if db.buffs.sizeOverride and db.buffs.sizeOverride > 0 then
			buffs:SetWidth(db.buffs.perrow * db.buffs.sizeOverride)
		end
		
		local x, y = E:GetXYOffset(db.buffs.anchorPoint)
		local attachTo = self:GetAuraAnchorFrame(frame, db.buffs.attachTo)
		
		buffs:Point(E.InversePoints[db.buffs.anchorPoint], attachTo, db.buffs.anchorPoint, x + db.buffs.xOffset, y + db.buffs.yOffset + (E.PixelMode and (db.buffs.anchorPoint:find('TOP') and -1 or 1) or 0))
		buffs:Height(buffs.size * rows)
		buffs['growth-y'] = db.buffs.anchorPoint:find('TOP') and 'UP' or 'DOWN'
		buffs['growth-x'] = db.buffs.anchorPoint == 'LEFT' and 'LEFT' or  db.buffs.anchorPoint == 'RIGHT' and 'RIGHT' or (db.buffs.anchorPoint:find('LEFT') and 'RIGHT' or 'LEFT')
		buffs.initialAnchor = E.InversePoints[db.buffs.anchorPoint]

		if db.buffs.enable then			
			buffs:Show()
			UF:UpdateAuraIconSettings(buffs)
		else
			buffs:Hide()
		end
	end
	
	do -- Дебаффы
		local debuffs = frame.Debuffs
		local rows = db.debuffs.numrows
		
		if USE_POWERBAR_OFFSET then
			debuffs:SetWidth(UNIT_WIDTH - POWERBAR_OFFSET)
		else
			debuffs:SetWidth(UNIT_WIDTH)
		end
		
		debuffs.forceShow = frame.forceShowAuras
		debuffs.num = db.debuffs.perrow * rows
		debuffs.size = db.debuffs.sizeOverride ~= 0 and db.debuffs.sizeOverride or ((((debuffs:GetWidth() - (debuffs.spacing*(debuffs.num/rows - 1))) / debuffs.num)) * rows)
		
		if db.debuffs.sizeOverride and db.debuffs.sizeOverride > 0 then
			debuffs:SetWidth(db.debuffs.perrow * db.debuffs.sizeOverride)
		end
		
		local x, y = E:GetXYOffset(db.debuffs.anchorPoint)
		local attachTo = self:GetAuraAnchorFrame(frame, db.debuffs.attachTo, db.debuffs.attachTo == 'BUFFS' and db.buffs.attachTo == 'DEBUFFS')
		
		debuffs:Point(E.InversePoints[db.debuffs.anchorPoint], attachTo, db.debuffs.anchorPoint, x + db.debuffs.xOffset, y + db.debuffs.yOffset)
		debuffs:Height(debuffs.size * rows)
		debuffs['growth-y'] = db.debuffs.anchorPoint:find('TOP') and 'UP' or 'DOWN'
		debuffs['growth-x'] = db.debuffs.anchorPoint == 'LEFT' and 'LEFT' or  db.debuffs.anchorPoint == 'RIGHT' and 'RIGHT' or (db.debuffs.anchorPoint:find('LEFT') and 'RIGHT' or 'LEFT')
		debuffs.initialAnchor = E.InversePoints[db.debuffs.anchorPoint]

		if db.debuffs.enable then			
			debuffs:Show()
			UF:UpdateAuraIconSettings(debuffs)
		else
			debuffs:Hide()
		end
	end	
	
	do -- Полоса заклинаний
		local castbar = frame.Castbar
		castbar:Width(db.castbar.width - (BORDER * 2))
		castbar:Height(db.castbar.height)
		
		if db.castbar.icon then -- Иконка
			castbar.Icon = castbar.ButtonIcon
			castbar.Icon.bg:Width(db.castbar.height + (E.Border * 2))
			castbar.Icon.bg:Height(db.castbar.height + (E.Border * 2))
			
			castbar:Width(db.castbar.width - castbar.Icon.bg:GetWidth() - (E.PixelMode and 1 or 5))
			castbar.Icon.bg:Show()
		else
			castbar.ButtonIcon.bg:Hide()
			castbar.Icon = nil
		end
		
		if db.castbar.spark then -- Искра
			castbar.Spark:Show()
		else
			castbar.Spark:Hide()
		end		
		
		castbar:ClearAllPoints()
		castbar:Point('TOPLEFT', frame, 'BOTTOMLEFT', BORDER, -(BORDER*2+BORDER))
		
		if db.castbar.enable and not frame:IsElementEnabled('Castbar') then
			frame:EnableElement('Castbar')
		elseif not db.castbar.enable and frame:IsElementEnabled('Castbar') then
			frame:DisableElement('Castbar')	
		end			
	end
	
	do -- РЕйдовая иконка
		local RI = frame.RaidIcon
		if db.raidicon.enable then
			frame:EnableElement('RaidIcon')
			RI:Show()
			RI:Size(db.raidicon.size)
			
			local x, y = self:GetPositionOffset(db.raidicon.attachTo)
			RI:ClearAllPoints()
			RI:Point(db.raidicon.attachTo, frame, db.raidicon.attachTo, x + db.raidicon.xOffset, y + db.raidicon.yOffset)	
		else
			frame:DisableElement('RaidIcon')	
			RI:Hide()
		end
	end
	
	if db.customTexts then -- Свой текст
		local customFont = UF.LSM:Fetch('font', UF.db.font)
		for objectName, _ in pairs(db.customTexts) do
			if not frame[objectName] then
				frame[objectName] = frame.RaisedElementParent:CreateFontString(nil, 'OVERLAY')
			end
			
			local objectDB = db.customTexts[objectName]

			if objectDB.font then
				customFont = UF.LSM:Fetch('font', objectDB.font)
			end
			
			frame[objectName]:FontTemplate(customFont, objectDB.size or UF.db.fontSize, objectDB.fontOutline or UF.db.fontOutline)
			frame:Tag(frame[objectName], objectDB.text_format or '')
			frame[objectName]:SetJustifyH(objectDB.justifyH or 'CENTER')
			frame[objectName]:ClearAllPoints()
			frame[objectName]:SetPoint(objectDB.justifyH or 'CENTER', frame, objectDB.justifyH or 'CENTER', objectDB.xOffset, objectDB.yOffset);
		end
	end
	
	do -- Проверка дистанции
		local range = frame.Range
		if db.rangeCheck then
			if not frame:IsElementEnabled('Range') then
				frame:EnableElement('Range')
			end

			range.outsideAlpha = E.db.unitframe.OORAlpha
		else
			if frame:IsElementEnabled('Range') then
				frame:DisableElement('Range')
			end				
		end
	end		

	frame:ClearAllPoints()
	if INDEX == 1 then
		if db.growthDirection == 'UP' then
			frame:Point('BOTTOMRIGHT', BossHeaderMover, 'BOTTOMRIGHT') -- Позиция
		else
			frame:Point('TOPRIGHT', BossHeaderMover, 'TOPRIGHT') -- Позиция
		end
	else
		if db.growthDirection == 'UP' then
			frame:Point('BOTTOMRIGHT', _G['ElvUF_Boss'..INDEX-1], 'TOPRIGHT', 0, 12 + db.castbar.height)
		else
			frame:Point('TOPRIGHT', _G['ElvUF_Boss'..INDEX-1], 'BOTTOMRIGHT', 0, -(12 + db.castbar.height))
		end
	end	

	BossHeader:Width(UNIT_WIDTH)
	BossHeader:Height(UNIT_HEIGHT + (UNIT_HEIGHT + 12 + db.castbar.height) * 3)	
	
	if UF.db.colors.transparentHealth then
		UF:ToggleTransparentStatusBar(true, frame.Health, frame.Health.bg);
	else
		UF:ToggleTransparentStatusBar(false, frame.Health, frame.Health.bg, (USE_PORTRAIT and USE_PORTRAIT_OVERLAY) ~= true);
	end
	
	if UF.db.colors.transparentPower then
		UF:ToggleTransparentStatusBar(true, frame.Power, frame.Power.bg);
	else
		UF:ToggleTransparentStatusBar(false, frame.Power, frame.Power.bg, true);
	end
	
	UF:ToggleTransparentStatusBar(UF.db.colors.transparentHealth, frame.Health, frame.Health.bg, true);
	UF:ToggleTransparentStatusBar(UF.db.colors.transparentPower, frame.Power, frame.Power.bg);
	
	frame:UpdateAllElements()
end

UF['unitgroupstoload']['boss'] = MAX_BOSS_FRAMES