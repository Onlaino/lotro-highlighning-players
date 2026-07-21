HighlightPlayers = HighlightPlayers or {}

HighlightPlayers.StatusSelector = {}

function HighlightPlayers.StatusSelector.New(
    parent,
    left,
    top,
    labels,
    onChanged,
    width,
    height,
    layout
)
    local selector = {
        labels = labels,
        labelId = nil,
        rows = {},
        listener = nil,
        localeListener = nil
    }

    local totalWidth = width or 320
    local totalHeight = height or 96
    local columns = layout ~= nil and layout.columns or 1
    local visibleRows = layout ~= nil and layout.visibleRows or nil
    local rowHeight = 30
    local columnGap = columns > 1 and 6 or 0

    local list = Turbine.UI.ListBox()
    list:SetParent(parent)
    list:SetPosition(left, top)
    list:SetSize(totalWidth - 17, totalHeight)

    local scroll = Turbine.UI.Lotro.ScrollBar()
    scroll:SetParent(parent)
    scroll:SetPosition(left + totalWidth - 10, top)
    scroll:SetSize(10, totalHeight)
    scroll:SetOrientation(Turbine.UI.Orientation.Vertical)
    list:SetVerticalScrollBar(scroll)

    function selector:UpdateSelection()
        for id, row in pairs(self.rows) do
            local selected = id == self.labelId
            row.button:SetEnabled(not selected)
            row.button:SetText(
                selected and row.name .. "  " ..
                    HighlightPlayers.Localization.Get("selected_marker") or
                    row.name
            )
        end
    end

    function selector:Rebuild()
        list:ClearItems()
        self.rows = {}

        local all = self.labels:GetAll()
        local rowCount = math.ceil(table.getn(all) / columns)
        local hasOverflow = visibleRows ~= nil and rowCount > visibleRows

        if visibleRows ~= nil then
            scroll:SetVisible(hasOverflow)
            list:SetSize(
                hasOverflow and totalWidth - 17 or totalWidth,
                totalHeight
            )
        end

        if self.labels:GetById(self.labelId) == nil then
            self.labelId = all[1] ~= nil and all[1].id or nil
        end

        local visualRow = nil
        local itemWidth = math.floor(
            (list:GetWidth() - columnGap * (columns - 1)) / columns
        )

        for index, label in ipairs(all) do
            local column = math.mod(index - 1, columns)
            if column == 0 then
                visualRow = Turbine.UI.Control()
                visualRow:SetSize(list:GetWidth(), rowHeight)
                list:AddItem(visualRow)
            end

            local currentId = label.id
            local item = Turbine.UI.Control()
            item:SetParent(visualRow)
            item:SetPosition(column * (itemWidth + columnGap), 0)
            item:SetSize(itemWidth, rowHeight)

            local button = Turbine.UI.Lotro.Button()
            button:SetParent(item)
            button:SetPosition(1, 3)
            button:SetSize(item:GetWidth() - 2, 24)
            button.Click = function()
                selector:SetLabelId(currentId, true)
            end

            local swatchBorder = Turbine.UI.Label()
            swatchBorder:SetParent(item)
            swatchBorder:SetPosition(1, 3)
            swatchBorder:SetSize(26, 24)
            swatchBorder:SetBackColor(Turbine.UI.Color.Black)
            swatchBorder:SetMouseVisible(false)

            local swatch = Turbine.UI.Label()
            swatch:SetParent(item)
            swatch:SetPosition(3, 5)
            swatch:SetSize(22, 20)
            swatch:SetBackColor(self.labels:GetColor(label))
            swatch:SetMouseVisible(false)

            self.rows[currentId] = {
                button = button,
                name = label.name
            }
        end

        self:UpdateSelection()
    end

    function selector:SetLabelId(labelId, notify)
        if self.labels:GetById(labelId) == nil then
            return false
        end

        self.labelId = labelId
        self:UpdateSelection()

        if notify == true and onChanged ~= nil then
            onChanged(labelId)
        end

        return true
    end

    function selector:GetLabelId()
        return self.labelId
    end

    function selector:Stop()
        if self.listener ~= nil then
            self.labels:RemoveListener(self.listener)
            self.listener = nil
        end
        if self.localeListener ~= nil then
            HighlightPlayers.Localization.RemoveListener(self.localeListener)
            self.localeListener = nil
        end
    end

    selector.listener = labels:AddListener(function()
        selector:Rebuild()
    end)
    selector.localeListener = HighlightPlayers.Localization.AddListener(
        function()
            selector:UpdateSelection()
        end
    )

    selector:Rebuild()
    return selector
end
