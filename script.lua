local w = platform.window:width()
local h = platform.window:height()
local BOX_HEIGHT = 60
local BOX_WIDTH = 250
local input_text = ""
local output_text = ""

function on.paint(gc)

    local titleText = "ChemCalc By Haoyun Qin (c) 2020"
    local tTw = gc:getStringWidth(titleText)
    gc:setColorRGB(0, 30, 120)
    gc:drawString(titleText, (w - tTw) / 2, 0)
    titleText = "Type in the chemical formula"
    tTw = gc:getStringWidth(titleText)
    gc:drawString(titleText, (w - tTw) / 2, 20)
    titleText = "Then press Enter"
    tTw = gc:getStringWidth(titleText)
    gc:drawString(titleText, (w - tTw) / 2, 40)
    
    gc:setColorRGB(255, 30, 30)
    gc:setPen("medium", "smooth")
    gc:drawRect((w - BOX_WIDTH) / 2, (h - BOX_HEIGHT) / 2, BOX_WIDTH, BOX_HEIGHT)
    
    gc:setColorRGB(0, 0, 0)
    gc:setFont("serif", "b", 16)
    local itw = gc:getStringWidth(input_text)
    local ith = gc:getStringHeight(input_text)
    gc:drawString(input_text, (w - itw) / 2, (h - ith) / 2)
    gc:setColorRGB(0, 100, 0)
    gc:setFont("serif", "r", 16)
    local otw = gc:getStringWidth(output_text)
    gc:drawString(output_text, (w - otw) / 2, 150)
end

function on.charIn(char)
    input_text = input_text..char
    platform.window:invalidate()
end

function on.backspaceKey()
    input_text = input_text:usub(0, -2)
    platform.window:invalidate()
end

function on.clearKey()
    input_text = ""
    platform.window:invalidate()
end

function on.enterKey()
    if (input_text == "") then
        output_text = "Error: Input cannot be empty"
        return
    end
    local c_arr = {}
    local c_arr_copy = {}
    local error_flag = false
    local N = string.len(input_text)
    for i = 1, N do
        c_arr[i] = string.byte(input_text, i)
        c_arr_copy[i] = string.char(c_arr[i])
    end
    local start_flag = 0
    local ans_flag = 0
    for i = 1, N do
        if (string.byte(input_text, i) == string.byte('(')) then
            start_flag = i
        end
        if (string.byte(input_text, i) == string.byte(')')) then
            local tmp_mass = subMass(string.sub(input_text, start_flag + 1, i - 1))
            if (tmp_mass < 0) then
                error_flag = true
            else
                print(tmp_mass)
                local tmp_num = 1
                if (i + 1 <= N) then
                    if (c_arr[i + 1] >= 48 and c_arr[i + 1] <= 57) then
                        tmp_num = c_arr[i + 1] - 48
                        c_arr_copy[i + 1] = ""
                        if (i + 2 <= N) then
                            if (c_arr[i + 2] >= 48 and c_arr[i + 2] <= 57) then
                                tmp_num = tmp_num * 10 + c_arr[i + 2] - 48
                                c_arr_copy[i + 2] = ""
                                if (i + 3 <= N) then
                                    if (c_arr[i + 3] >= 48 and c_arr[i + 3] <= 57) then
                                        tmp_num = tmp_num * 10 + c_arr[i + 3] - 48
                                        c_arr_copy[i + 3] = ""
                                    end
                                end
                            end
                        end
                    end
                end
                print(tmp_num)
                print(tmp_mass)
                tmp_mass = tmp_mass * tmp_num
                if (math.floor(tmp_mass) ~= tmp_mass) then
                    ans_flag = ans_flag + tmp_mass - math.floor(tmp_mass)
                    tmp_mass = math.floor(tmp_mass)
                end
                print(tmp_mass)
                for k = start_flag, i do
                    c_arr_copy[k] = ''
                end
                c_arr_copy[i] = 'H'..tmp_mass
            end
        end
    end
    local working_text = ''
    for i = 1, N do
        working_text = working_text..c_arr_copy[i]
    end
    print(working_text)
    N = string.len(working_text)
    for i = 1, N do
        c_arr[i] = string.byte(working_text, i)
    end
    local ans = 0
    local last_upper = -100000
    local last_lower = 0
    local num = 0
    local tmp_ans = 0
    --- up: 1, down: 2, num: 3
    local last_kind = 0
    for i = 1, N do
        local c = c_arr[i]
        
        if (c >= 48 and c <= 57) then
            if (last_kind == 0) then
                error_flag = true
            end
            
            num = num * 10 + c - 48
            last_kind = 3
        end
        if (c >= 65 and c <= 90) then
            --- calculate ---
            if (last_upper > 0) then
                if (last_lower == 0) then
                    if (num == 0) then
                        ans = ans + getMass(string.char(last_upper))
                    else
                        ans = ans + getMass(string.char(last_upper)) * num
                    end
                else
                    if (num == 0) then
                        ans = ans + getMass(string.char(last_upper, last_lower))
                    else
                        ans = ans + getMass(string.char(last_upper, last_lower)) * num
                    end
                end
            end
            num = 0
            last_upper = c
            last_lower = 0
            last_kind = 1
        end
        if (c >= 97 and c <= 122) then
            if (last_kind == 0) then
                error_flag = true
            end
            if (last_kind == 2 or last_kind == 3) then
                error_flag = true
            end
            num = 0
            last_lower = c
            last_kind = 2
        end
    end
    if (error_flag == false) then
        if (last_lower == 0) then
            if (num == 0) then
                ans = ans + getMass(string.char(last_upper))
            else
                ans = ans + getMass(string.char(last_upper)) * num
            end
        else
            if (num == 0) then
                ans = ans + getMass(string.char(last_upper, last_lower))
            else
                ans = ans + getMass(string.char(last_upper, last_lower)) * num
            end
        end
    end
    ans = ans + ans_flag
    if (error_flag == false) then
        output_text = "M("..input_text..")="..ans
    else
        output_text = "Error: Wrong Format"
    end
    platform.window:invalidate()
end

function subMass(text)
    local c_arr = {}
    local N = string.len(text)
    for i = 1, N do
        c_arr[i] = string.byte(text, i)
    end
    
    local ans = 0
    local last_upper = -100000
    local last_lower = 0
    local num = 0
    local error_flag = false
    --- up: 1, down: 2, num: 3
    local last_kind = 0
    for i = 1, N do
        local c = c_arr[i]
        
        if (c >= 48 and c <= 57) then
            if (last_kind == 0) then
                error_flag = true
            end
            num = num * 10 + c - 48
            
            last_kind = 3
        end
        if (c >= 65 and c <= 90) then
            --- calculate ---
            if (last_upper > 0) then
                if (last_lower == 0) then
                    if (num == 0) then
                        ans = ans + getMass(string.char(last_upper))
                    else
                        ans = ans + getMass(string.char(last_upper)) * num
                    end
                else
                    if (num == 0) then
                        ans = ans + getMass(string.char(last_upper, last_lower))
                    else
                        ans = ans + getMass(string.char(last_upper, last_lower)) * num
                    end
                end
            end
            num = 0
            last_upper = c
            last_lower = 0
            last_kind = 1
        end
        if (c >= 97 and c <= 122) then
            if (last_kind == 0) then
                error_flag = true
            end
            if (last_kind == 2 or last_kind == 3) then
                error_flag = true
            end
            num = 0
            last_lower = c
            last_kind = 2
        end
    end
    if (error_flag == false) then
        if (last_lower == 0) then
            if (num == 0) then
                ans = ans + getMass(string.char(last_upper))
            else
                ans = ans + getMass(string.char(last_upper)) * num
            end
        else
            if (num == 0) then
                ans = ans + getMass(string.char(last_upper, last_lower))
            else
                ans = ans + getMass(string.char(last_upper, last_lower)) * num
            end
        end
    end
    if (error_flag == false) then
        return ans
    else
        return -1000000
    end
    platform.window:invalidate()
end

function getMass(c)
    if (c == 'H') then
        return 1.008
    end
    if (c == 'He') then
        return 4.00
    end
    if (c == 'Li') then
        return 6.94
    end
    if (c == 'Be') then
        return 9.01
    end
    if (c == 'B') then
        return 10.81
    end
    if (c == 'C') then
        return 12.01
    end
    if (c == 'N') then
        return 14.01
    end
    if (c == 'O') then
        return 16.00
    end
    if (c == 'F') then
        return 19.00
    end
    if (c == 'Ne') then
        return 20.18
    end
    if (c == 'Na') then
        return 22.99
    end
    if (c == 'Mg') then
        return 24.30
    end
    if (c == 'Al') then
        return 26.98
    end
    if (c == 'Si') then
        return 28.09
    end
    if (c == 'P') then
        return 30.97
    end
    if (c == 'S') then
        return 32.06
    end
    if (c == 'Cl') then
        return 35.45
    end
    if (c == 'Ar') then
        return 39.95
    end
    if (c == 'K') then
        return 39.10
    end
    if (c == 'Ca') then
        return 40.08
    end
    if (c == 'Sc') then
        return 44.96
    end
    if (c == 'Ti') then
        return 47.87
    end
    if (c == 'V') then
        return 50.94
    end
    if (c == 'Cr') then
        return 52.00
    end
    if (c == 'Mn') then
        return 54.94
    end
    if (c == 'Fe') then
        return 55.85
    end
    if (c == 'Co') then
        return 58.93
    end
    if (c == 'Ni') then
        return 58.69
    end
    if (c == 'Cu') then
        return 63.55
    end
    if (c == 'Zn') then
        return 65.38
    end
    if (c == 'Ga') then
        return 69.72
    end
    if (c == 'Ge') then
        return 72.63
    end
    if (c == 'As') then
        return 74.92
    end
    if (c == 'Se') then
        return 78.97
    end
    if (c == 'Br') then
        return 79.90
    end
    if (c == 'Kr') then
        return 83.80
    end
    if (c == 'Rb') then
        return 85.47
    end
    if (c == 'Sr') then
        return 87.62
    end
    if (c == 'Y') then
        return 88.91
    end
    if (c == 'Zr') then
        return 91.22
    end
    if (c == 'Nb') then
        return 92.91
    end
    if (c == 'Mo') then
        return 95.95
    end
    if (c == 'Tc') then
        return 97
    end
    if (c == 'Ru') then
        return 101.1
    end
    if (c == 'Rh') then
        return 102.91
    end
    if (c == 'Pd') then
        return 106.42
    end
    if (c == 'Ag') then
        return 107.87
    end
    if (c == 'Cd') then
        return 112.41
    end
    if (c == 'In') then
        return 114.82
    end
    if (c == 'Sn') then
        return 118.71
    end
    if (c == 'Sb') then
        return 121.76
    end
    if (c == 'Te') then
        return 127.60
    end
    if (c == 'I') then
        return 126.90
    end
    if (c == 'Xe') then
        return 131.29
    end
    if (c == 'Cs') then
        return 132.91
    end
    if (c == 'Ba') then
        return 137.33
    end
    if (c == 'W') then
        return 183.84
    end
    if (c == 'Ir') then
        return 192.2
    end
    if (c == 'Pt') then
        return 195.08
    end
    if (c == 'Au') then
        return 196.97
    end
    if (c == 'Hg') then
        return 200.59
    end
    if (c == 'Tl') then
        return 204.38
    end
    if (c == 'Pb') then
        return 207.2
    end
    if (c == 'Bi') then
        return 208.98
    end
    if (c == 'Po') then
        return 209
    end
    if (c == 'At') then
        return 210
    end
    if (c == 'Ac') then
        return 59.044
    end
    return -10000
end
