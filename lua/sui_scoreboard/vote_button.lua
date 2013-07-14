local PANEL = {}

PANEL.VoteName = "none"
PANEL.MaterialName = "exclamation"

--- Init
function PANEL:Init()
	self.Label = vgui.Create( "DLabel", self )
	self:ApplySchemeSettings()
	self:SetCursor( "hand" )	
end

--- DoClick
function PANEL:DoClick()
	local ply = self:GetParent().Player
	if not ply or not ply:IsValid() or ply == LocalPlayer() then
		return false
	end
	
	LocalPlayer():ConCommand( "sui_rateuser ".. ply:EntIndex().. " "..self.VoteName.."\n" )
end

---ApplySchemeSettings
function PANEL:ApplySchemeSettings()	
	self.Label:SetFont( "suiscoreboardcardinfo" )
	self.Label:SetColor( Color(0,0,0,255) )
	self.Label:SetFGColor( 0, 0, 0, 150 )
	self.Label:SetMouseInputEnabled( false )
end

--- PerformLayout
function PANEL:PerformLayout()	
	if self:GetParent().Player and self:GetParent().Player:IsValid() then
		self.Label:SetText( self:GetParent().Player:GetNetworkedInt( "SuiRating."..self.VoteName, 0 ) )
	end
	
	self.Label:SizeToContents()
	self.Label:SetPos( (self:GetWide() - self.Label:GetWide()) / 2, self:GetTall() - self.Label:GetTall() )
end

--- SetUp
function PANEL:SetUp( mat, votename, nicename )
	self.MaterialName 	= mat
	self.VoteName 		= votename
	self.NiceName		= nicename
	self:SetToolTip( self.NiceName )
end

--- Paint
function PANEL:Paint(w,h)	
	if not self.Material then
		self.Material = surface.GetTextureID( "gui/" .. self.MaterialName )
	end
	
	local bgColor = Color( 200,200,200,100 )

	if self.Selected then
		bgColor = Color( 135, 135, 135, 100 )
	elseif self.Armed then
		bgColor = Color( 175, 175, 175, 100 )
	end
	
	draw.RoundedBox( 4, 0, 0, self:GetWide(), self:GetTall(), bgColor )
	
	local alpha = 225
	if self.Armed then
		alpha = 255
	end
	
	surface.SetTexture( self.Material )
	if self.VoteName == "best_airvehicle" then
		surface.SetDrawColor( 100, 100, 255, alpha )
		surface.DrawTexturedRect( self:GetWide()/2 - 8, self:GetWide()/2 - 8, 16, 16 ) 
	elseif self.VoteName == "lol" then
		surface.SetDrawColor( 255, 155, 0, alpha )
		surface.DrawTexturedRect( self:GetWide()/2 - 8, self:GetWide()/2 - 8, 16, 16 ) 
	elseif self.VoteName == "best_landvehicle" then
		surface.SetDrawColor( 0, 0, 0, alpha )
		surface.DrawTexturedRect( self:GetWide()/2 - 12, self:GetWide()/2 - 12, 24, 24 ) 
	elseif self.VoteName == "god" then
		surface.SetDrawColor( 255, 255, 255, alpha )
		surface.DrawTexturedRect( self:GetWide()/2 - 13, self:GetWide()/2 - 8, 26, 26 ) 
	elseif self.VoteName == "gay" then
		surface.SetDrawColor( 255, 0, 215, alpha )
		surface.DrawTexturedRect( self:GetWide()/2 - 13, self:GetWide()/2 - 8, 26, 26 ) 
	else
		surface.SetDrawColor( 255, 255, 255, alpha )
		surface.DrawTexturedRect( self:GetWide()/2 - 8, self:GetWide()/2 - 8, 16, 16 ) 
	end	
	
	return true
end

local TooltipText = nil

--- OnCursorEntered
function PANEL:OnCursorEntered()
	TooltipText = self.NiceName	
end

--- OnCursorExited
function PANEL:OnCursorExited()
	TooltipText = nil	
end

vgui.Register( "suispawnmenuvotebutton", PANEL, "Button" )

local _GetTooltipText = GetTooltipText

--- GetTooltipText 
-- @return string
function GetTooltipText()

	if TooltipText then 
		return TooltipText
	end

	return _GetTooltipText()	
end