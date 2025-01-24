--[[

SUI Scoreboard v2.6 by .Z. Dathus [BR] is licensed under a Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License.
----------------------------------------------------------------------------------------------------------------------------
Copyright (c) 2014 - 2024 Dathus [BR] <http://www.juliocesar.me> <http://steamcommunity.com/profiles/76561197983103320>

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License.
To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/4.0/deed.en_US.
----------------------------------------------------------------------------------------------------------------------------
This Addon is based on the original SUI Scoreboard v2 developed by suicidal.banana.
Copyright only on the code that I wrote, my implementation and fixes and etc, The Initial version (v2) code still is from suicidal.banana.
----------------------------------------------------------------------------------------------------------------------------

$Id$
Version 2.7 - 2024-05-19 11:25 AM (UTC -03:00)

]]--

include( "player_row.lua" )
include( "connecting_player_row.lua" )
include( "player_frame.lua" )

local CurTime = CurTime

surface.CreateFont( "suiscoreboardheader"  , { font = "consolas", size = 28, weight = 1000, antialiasing = true})
surface.CreateFont( "suiscoreboardsubtitle", { font = "consolas", size = 20, weight = 1000, antialiasing = true})
surface.CreateFont( "suiscoreboardlogotext", { font = "coolvetica", size = 75, weight = 100, antialiasing = true})
surface.CreateFont( "suiscoreboardsuisctext", { font = "bahnschrift", size = 12, weight = 100, antialiasing = true})
surface.CreateFont( "suiscoreboardplayername", { font = "bahnschrift", size = 17, weight = 5, antialiasing = true})
surface.CreateFont( "suiscoreboardsuiscinfo", { font = "bahnschrift", size = 13, weight = 50, antialiasing = true})

local texGradient = surface.GetTextureID( "gui/center_gradient" )

local outerBoxColor = Color( 14, 18, 25, 205 )
local innerBoxColor = Color( 23, 25, 36, 100 )
local subHeaderColor = Color( 14, 18, 25, 155 )
local sectionLabelColor = Color( 255, 255, 227, 255 )
local infoLabelColor = Color( 0, 0, 0, 255 )

local function ColorCmp( c1, c2 )
	if not c1 or not c2 then
		return false
	end

	return c1.r == c2.r and c1.g == c2.g and c1.b == c2.b and c1.a == c2.a
end

local PANEL = {}

--- Init
function PANEL:Init()
	Scoreboard.vgui = self
	self.Hostname = vgui.Create( "DLabel", self )
	self.Hostname:SetText( GetHostName() )

	self.Logog = vgui.Create( "DLabel", self )
	self.Logog:SetText( "g" )

	self.SuiSc = vgui.Create( "DLabel", self )
	self.SuiSc:SetText( "SUI Scoreboard v" .. Scoreboard.version .. " by Dathus [BR]" )
	self.SuiSc:SetCursor( "hand" )
	self.SuiSc.DoClick = function() gui.OpenURL("https://steamcommunity.com/profiles/76561197983103320") end
	self.SuiSc:SetMouseInputEnabled( true )

	self.Description = vgui.Create( "DLabel", self )
	--self.Description:SetText( GAMEMODE.Name .. " - " .. GAMEMODE.Author )

	self.PlayerFrame = vgui.Create( "suiplayerframe", self )

	self.PlayerRows = {}

	self:UpdateScoreboard()

	-- Update the scoreboard every 1 second
	timer.Create( "Scoreboard.vguiUpdater", 1, 0, self.UpdateScoreboard )

	self.lblPing = vgui.Create( "DLabel", self )
	self.lblPing:SetText( "Ping" )

	self.lblKills = vgui.Create( "DLabel", self )
	self.lblKills:SetText( "Kills" )

	self.lblDeaths = vgui.Create( "DLabel", self )
	self.lblDeaths:SetText( "Deaths" )

	self.lblRatio = vgui.Create( "DLabel", self )
	self.lblRatio:SetText( "Ratio" )

	self.lblHealth = vgui.Create( "DLabel", self )
	self.lblHealth:SetText( "Health" )

	self.lblHours = vgui.Create( "DLabel", self )
	self.lblHours:SetText( "Total Time Connected" )

	self.lblTeam = vgui.Create( "DLabel", self )
	self.lblTeam:SetText( "Rank" )

	self.lblStatus = vgui.Create( "DLabel", self )
	self.lblStatus:SetText( "Status" )

	self.lblMute = vgui.Create( "DImageButton", self)

	self.connectingPlayers = {}

	net.Receive("SUIScoreboardPlayerConnecting", function()
		local id = net.ReadInt(32)
		local name = net.ReadString()
		local steamid = net.ReadString()
		local steamid64 = net.ReadString()

		self.connectingPlayers[id] = {name, steamid, steamid64}
	end )

	gameevent.Listen( "player_disconnect" )
	hook.Add( "player_disconnect", "suiscoreboardPlayerDisconnect", function( data )
		local name = data.name			-- Same as Player:Nick()
		local steamid = data.networkid	-- Same as Player:SteamID()
		local id = data.userid			-- Same as Player:UserID()
		local bot = data.bot			-- Same as Player:IsBot()
		local reason = data.reason		-- Text reason for disconnected such as "Kicked by console!", "Timed out!", etc...

		self.connectingPlayers[id] = nil
	end )

	gameevent.Listen( "player_spawn" )
	hook.Add( "player_spawn", "suiscoreboardPlayerSpawn", function( data )
		local id = data.userid	-- Same as Player:UserID()

		self.connectingPlayers[id] = nil
	end )
end

--- AddPlayerRow
function PANEL:AddPlayerRow( ply )
	if(type(ply) == "table") then
		local button = vgui.Create( "suiscoreconnectingplayerrow", self.PlayerFrame:GetCanvas() )
		button:SetPlayer( ply[1], ply[2], ply[3] )
		self.PlayerRows[ ply[1] ] = button
	else
		local button = vgui.Create( "suiscoreplayerrow", self.PlayerFrame:GetCanvas() )
		button:SetPlayer( ply )
		self.PlayerRows[ ply ] = button
	end
end

--- GetPlayerRow
function PANEL:GetPlayerRow( ply )
	return self.PlayerRows[ ply ]
end

--- Paint
function PANEL:Paint(w,h)
	draw.RoundedBox( 10, 0, 0, self:GetWide(), self:GetTall(), outerBoxColor )
	surface.SetTexture( texGradient )
	surface.SetDrawColor( 64, 68, 75, 155 )
	surface.DrawTexturedRect( 0, 0, self:GetWide(), self:GetTall() )

	-- White Inner Box
	draw.RoundedBox( 6, 15, self.Description.y - 8, self:GetWide() - 30, self:GetTall() - self.Description.y - 6, innerBoxColor )
	surface.SetTexture( texGradient )
	surface.SetDrawColor( 48, 50, 61, 50 )
	surface.DrawTexturedRect( 15, self.Description.y - 8, self:GetWide() - 30, self:GetTall() - self.Description.y - 8 )

	-- Sub Header
	draw.RoundedBox( 6, 108, self.Description.y - 4, self:GetWide() - 128, self.Description:GetTall() + 8, subHeaderColor )
	surface.SetTexture( texGradient )
	surface.SetDrawColor( 64, 68, 75, 50 )
	surface.DrawTexturedRect( 108, self.Description.y - 4, self:GetWide() - 128, self.Description:GetTall() + 8 )

  -- Logo!
  if Scoreboard.playerColor.r < 255 then
    tColorGradientR = Scoreboard.playerColor.r + 15
  else
    tColorGradientR = Scoreboard.playerColor.r
  end

  if Scoreboard.playerColor.g < 255 then
    tColorGradientG = Scoreboard.playerColor.g + 15
  else
    tColorGradientG = Scoreboard.playerColor.g
  end

  if Scoreboard.playerColor.b < 255 then
    tColorGradientB = Scoreboard.playerColor.b + 15
  else
    tColorGradientB = Scoreboard.playerColor.b
  end

	draw.RoundedBox( 8, 24, 12, 80, 80, Color( Scoreboard.playerColor.r, Scoreboard.playerColor.g, Scoreboard.playerColor.b, 200 ) )
	surface.SetTexture( texGradient )
	surface.SetDrawColor( tColorGradientR, tColorGradientG, tColorGradientB, 225 )
	surface.DrawTexturedRect( 24, 12, 80, 80 )
end

--- PerformLayout
function PANEL:PerformLayout()
	self:SetSize( ScrW() * 0.75, ScrH() * 0.65 )

	self:SetPos( (ScrW() - self:GetWide()) / 2, (ScrH() - self:GetTall()) / 2 )

	self.Hostname:SizeToContents()
	self.Hostname:SetPos( 115, 17 )

	self.Logog:SetSize( 80, 80 )
	self.Logog:SetPos( 45, 5 )

	self.SuiSc:SetSize( 200, 15 )
	self.SuiSc:SetPos( (self:GetWide() - 200), (self:GetTall() - 15) )

	self.Description:SizeToContents()
	self.Description:SetPos( 115, 60 )

	self.PlayerFrame:SetPos( 5, self.Description.y + self.Description:GetTall() + 20 )
	self.PlayerFrame:SetSize( self:GetWide() - 10, self:GetTall() - self.PlayerFrame.y - 20 )

	local y = 0

	local PlayerSorted = {}

	for _, v in pairs( self.PlayerRows ) do
		table.insert( PlayerSorted, v )
	end

	table.sort( PlayerSorted, function ( a, b ) return a:HigherOrLower( b ) end )

	for _, v in ipairs( PlayerSorted ) do
		v:SetPos( 0, y )
		v:SetSize( self.PlayerFrame:GetWide(), v:GetTall() )

		self.PlayerFrame:GetCanvas():SetSize( self.PlayerFrame:GetCanvas():GetWide(), y + v:GetTall() )
		y = y + v:GetTall() + 1
	end

	-- self.Hostname:SetText( GetGlobalString( "ServerName","Garry's Mod 13" ) )
	self.Hostname:SetText( GetHostName() )

	self.lblPing:SizeToContents()
	self.lblKills:SizeToContents()
	self.lblRatio:SizeToContents()
	self.lblDeaths:SizeToContents()
	self.lblHealth:SizeToContents()
	self.lblHours:SizeToContents()
	self.lblTeam:SizeToContents()
	self.lblStatus:SizeToContents()

	local COLUMN_SIZE = 45

	self.lblPing:SetPos( self:GetWide() - COLUMN_SIZE*2 - self.lblPing:GetWide()/2, self.PlayerFrame.y - self.lblPing:GetTall() - 3  )
	self.lblRatio:SetPos( self:GetWide() - COLUMN_SIZE*3.2 - self.lblDeaths:GetWide()/2, self.PlayerFrame.y - self.lblPing:GetTall() - 3  )
	self.lblDeaths:SetPos( self:GetWide() - COLUMN_SIZE*4.4 - self.lblDeaths:GetWide()/2, self.PlayerFrame.y - self.lblPing:GetTall() - 3  )
	self.lblKills:SetPos( self:GetWide() - COLUMN_SIZE*5.4 - self.lblKills:GetWide()/2, self.PlayerFrame.y - self.lblPing:GetTall() - 3  )
	self.lblHealth:SetPos( self:GetWide() - COLUMN_SIZE*6.4 - self.lblKills:GetWide()/2, self.PlayerFrame.y - self.lblPing:GetTall() - 3  )
	self.lblHours:SetPos( self:GetWide() - COLUMN_SIZE*10.2 - self.lblKills:GetWide()/2, self.PlayerFrame.y - self.lblPing:GetTall() - 3  )
	self.lblTeam:SetPos( self:GetWide() - COLUMN_SIZE*16 - self.lblKills:GetWide()/2, self.PlayerFrame.y - self.lblPing:GetTall() - 3  )
	self.lblStatus:SetPos( self:GetWide() - COLUMN_SIZE*16 - self.lblKills:GetWide()/2, self.PlayerFrame.y - self.lblPing:GetTall() - 3  )
end

--- ApplySchemeSettings
function PANEL:ApplySchemeSettings()
	self.Hostname:SetFont( "suiscoreboardheader" )
	self.Description:SetFont( "suiscoreboardsubtitle" )
	self.Logog:SetFont( "suiscoreboardlogotext" )
	self.SuiSc:SetFont( "suiscoreboardsuisctext" )

  if evolve == nil then
    tColor = team.GetColor(LocalPlayer():Team())
  else
    tColor = evolve.ranks[ LocalPlayer():EV_GetRank() ].Color
  end

	self.Hostname:SetFGColor( Color( tColor.r, tColor.g, tColor.b, 255 ) )
	self.Description:SetFGColor( sectionLabelColor )

	self.Logog:SetFGColor( Color(tColor.r,tColor.g,tColor.b,225)   )
	self.SuiSc:SetFGColor( Color( 255, 255, 227, 200 ) )

	self.lblPing:SetFont( "suiscoreboardsuiscinfo" )
	self.lblKills:SetFont( "suiscoreboardsuiscinfo" )
	self.lblDeaths:SetFont( "suiscoreboardsuiscinfo" )
	self.lblTeam:SetFont( "suiscoreboardsuiscinfo" )
	self.lblHealth:SetFont( "suiscoreboardsuiscinfo" )
	self.lblRatio:SetFont( "suiscoreboardsuiscinfo" )
	self.lblHours:SetFont( "suiscoreboardsuiscinfo" )
  	self.lblStatus:SetFont( "suiscoreboardsuiscinfo" )

	self.lblPing:SetColor( sectionLabelColor )
	self.lblKills:SetColor( sectionLabelColor )
	self.lblDeaths:SetColor( sectionLabelColor )
	self.lblTeam:SetColor( sectionLabelColor )
	self.lblHealth:SetColor( sectionLabelColor )
	self.lblRatio:SetColor( sectionLabelColor )
	self.lblHours:SetColor( sectionLabelColor )
  	self.lblStatus:SetColor( sectionLabelColor )

	self.lblPing:SetFGColor( infoLabelColor )
	self.lblKills:SetFGColor( infoLabelColor )
	self.lblDeaths:SetFGColor( infoLabelColor )
	self.lblTeam:SetFGColor( infoLabelColor )
	self.lblHealth:SetFGColor( infoLabelColor )
	self.lblRatio:SetFGColor( infoLabelColor )
	self.lblHours:SetFGColor( infoLabelColor )
  	self.lblStatus:SetFGColor( infoLabelColor )
end

--- UpdateScoreboard
function PANEL:UpdateScoreboard( force )
	if not self then return end
	if not force and not self:IsVisible() then
		return false
	end

	for k, v in pairs( self.PlayerRows ) do
		if type(k) == "string" then
			v:Remove()
			self.PlayerRows[ k ] = nil
		elseif not IsValid(k) then
			v:Remove()
			self.PlayerRows[ k ] = nil
		end
	end

	local PlayerList = player.GetAll()
	PlayerList = table.Add(PlayerList, self.connectingPlayers)

	for _, pl in ipairs( PlayerList ) do
		if not self:GetPlayerRow( pl ) then
			self:AddPlayerRow( pl )
		end
	end

	-- Always invalidate the layout so the order gets updated
	self:InvalidateLayout()
end

--- Think
function PANEL:Think()
	if not self.UptimeUpdate or self.UptimeUpdate < CurTime() then
		self.UptimeUpdate = CurTime() + 0.5
		self.Description:SetText( "Server Uptime: " .. Scoreboard.formatTime( CurTime() ) )
	end
end

vgui.Register( "suiscoreboard", PANEL, "Panel" )
