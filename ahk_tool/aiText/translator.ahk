#SingleInstance Force
#NoEnv
SetWorkingDir %A_ScriptDir%
#Include %A_ScriptDir%\JSON.ahk

; 设置UTF-8编码
FileEncoding, UTF-8
global mainName := "文本处理工具"

;api参数
global apiUrl, apiKey, selectedModel, modelList
;主窗口宽高
global  mainHeight, mainWidth, mainClientWidth, mainClientHeight
;prompt设置界面宽高
global promptWidth, promptHeight, promptList
;控件变量
global SelectedPromptText, OutputText
global promptMap := {}
global promptOrder := []  ; 用于存储插入顺序
global dynamicButtonTitles := []
promptMap["Default"] = "你是工作助手"

; 读取配置
LoadConfig()


; 创建主窗口
Gui, Main:New
Gui, Main:+Resize +MinSize500x450  ; 将Resize选项移到这里
Gui, Main:Margin, 10, 10
;禁用 DPI 缩放
Gui -DPIScale
; 设置字体
Gui, Main:Font, s10, Microsoft YaHei

; 添加输入框 - 浅绿色背景
outputWidth := mainWidth - 30
Gui, Main:Add, Edit, vInputText w%outputWidth% h150 Background98FB98

; 添加按钮行 - 第一行
Gui, Main:Add, Button, xm y+10 w80 h30 gButtonPrompt, Prompt
Gui, Main:Add, Text, x+5 yp+5 w100 vSelectedPromptText, ; 显示选中的prompt名称

; 发送和设置按钮放在第一行最右边
btnPosion1 := outputWidth - 40 -100 -80 - 80 -80
Gui, Main:Add, Button, x+%btnPosion1% w80 h30 gButtonSettings, 设置API
Gui, Main:Add, Button, x+5 w80 h30 gButtonSend, 发送

; 功能按钮放在第二行
;填加promptOrder前4个按钮
Gui, Main:Add, Button, xm y+10 w80 h30 gButtonTranslate, 翻译
addBtn := 0
for idx, promptName in promptOrder
{   if(addBtn > 2) {
        break
    }
    if(promptName == "翻译" || promptName == "Default") {
        Continue
    } else {
        Gui, Main:Add, Button, x+5 w80 h30 gButtonQuick, %promptName%
        addBtn += 1
        dynamicButtonTitles.Push(promptName)
    }
}


; 添加输出框
outputHeight := mainClientHeight - 30 - 30 - 150 - 50
Gui, Main:Add, Edit, xm y+10 vOutputText w%outputWidth% h%outputHeight% ReadOnly

; 显示GUI
Gui, Main:Show, w%mainClientWidth% h%mainClientHeight%, %mainName%

; 加载默认选中的 Prompt
IniRead, defaultPrompt, config.ini, Defaults, SelectedPrompt, 翻译
; 根据默认 Prompt 加载对应的内容作为 sysPrompt
global sysPrompt := promptMap["Default"]
if(promptMap[defaultPrompt]) {
    sysPrompt :=  promptMap[defaultPrompt]
}
; print(defaultPrompt , sysPrompt)
GuiControl, Main:, SelectedPromptText, %defaultPrompt%
return


LoadConfig() {

    IniRead, apiUrl, config.ini, API, apiUrl, https://api.deepseek.com
    IniRead, apiKey, config.ini, API, apiKey, your-api-key
    IniRead, selectedModel, config.ini, API, selectedModel, deepseek-chat
    IniRead, modelList, config.ini, API, availableModels, deepseek-chat

    ; 加载 prompt 列表
    promptList := ""
    IniRead, sections, config.ini, Prompts
    if (sections != "ERROR") {
        Loop, Parse, sections, `n
        {
            ; 只取等号前面的部分作为名称
            spt := StrSplit(A_LoopField, "=")
            if (spt.Length() > 1){
                promptList .= spt[1] "|"
                ;保存到promptMap
                promptMap[spt[1]] := spt[2]
                promptOrder.Push(spt[1])
            }
        }
    }
    ; 添加默认 prompt
    if (!promptList) {
        promptList := "翻译|总结|润色|解释"
        ; 保存默认 prompt，使用 \n 作为换行符
        IniWrite, 下面我让你来充当翻译家，你的目标是把任何语言翻译成中文，请翻译时不要带翻译腔，而是要翻译得自然、流畅和地道，使用优美和高雅的表达方式。, config.ini, Prompts, 翻译
        IniWrite, 请帮我总结以下内容，要求简明扼要，突出重点。, config.ini, Prompts, 总结
        IniWrite, 请帮我润色以下文字，使其更加优美流畅，符合中文表达习惯。, config.ini, Prompts, 润色
        IniWrite, 请解释以下内容，使用通俗易懂的语言，可以举例说明。, config.ini, Prompts, 解释
        promptMap["翻译"] := "下面我让你来充当翻译家，你的目标是把任何语言翻译成中文，请翻译时不要带翻译腔，而是要翻译得自然、流畅和地道，使用优美和高雅的表达方式。"
        promptMap["总结"] := "请帮我总结以下内容，要求简明扼要，突出重点。"
        promptMap["润色"] := "请帮我润色以下文字，使其更加优美流畅，符合中文表达习惯。"
        promptMap["解释"] := "请解释以下内容，使用通俗易懂的语言，可以举例说明。"
        promptOrder.Push("翻译","总结","润色","解释")
    }

    ; 添加窗口大小配置读取
    IniRead, mainWidth, config.ini, WindowSize, mainWidth, 700
    IniRead, mainHeight, config.ini, WindowSize, mainHeight, 450

    ; 计算补偿值（边框和标题栏）
    SysGet, BorderWidth, 32  ; SM_CXSIZEFRAME 或 SM_CXFRAME
    SysGet, BorderHeight, 33  ; SM_CYSIZEFRAME 或 SM_CYFRAME
    SysGet, TitleHeight, 4   ; SM_CYCAPTION

    ; 补偿窗口大小
    mainClientWidth := mainWidth - (BorderWidth * 2)
    mainClientHeight := mainHeight - (BorderHeight * 2) - TitleHeight

    ; 添加设置窗口大小配置读取
    IniRead, settingsWidth, config.ini, WindowSize, settingsWidth, 400
    IniRead, settingsHeight, config.ini, WindowSize, settingsHeight, 300
    IniRead, promptWidth, config.ini, WindowSize, promptWidth
    IniRead, promptHeight, config.ini, WindowSize, promptHeight
    ; 添加默认 prompt 编辑窗口宽高
    if (promptWidth == "ERROR") {
        promptWidth := 600
        promptHeight := 500
        IniWrite, 600, config.ini, WindowSize, promptWidth
        IniWrite, 500, config.ini, WindowSize, promptHeight
    }

}

setSendData(selectedModel, sysPrompt, userPrompt){
    ; theSysPrompt := RegExReplace(sysPrompt, "\r\n|\n|\r", "\n")
    ; 转义特殊字符
    theUserPrompt := RegExReplace(theUserPrompt, "\\", "\\\\")     ; 转义反斜杠, 必须放在开头
    theUserPrompt := RegExReplace(userPrompt, "\r\n|\n|\r", "\n")  ; 处理换行符
    theUserPrompt := RegExReplace(theUserPrompt, """", "\""")      ; 转义双引号
    sendData := "
    (
        {
            ""model"": """ selectedModel """,
            ""messages"": [
                {
                ""role"": ""system"",
                ""content"": """ sysPrompt """
                },
                {
                ""role"": ""user"",
                ""content"": """ theUserPrompt """
                }
            ]
        }
    )"
    return sendData
}

sendRequest(sysPrompt, userPrompt){
    Gui, Main:Submit, NoHide
    ; 构建请求sendData
    sendData := setSendData(selectedModel, sysPrompt, userPrompt)
    ;print("sendData:",sendData)
    ; 发送请求
    HttpPostStream(apiUrl "/v1/chat/completions", apiKey, sendData)
    ; response := HttpPost(apiUrl "/v1/chat/completions", apiKey, sendData)

    ; if (response) {  ; 只在有响应时处
    ;     try {
    ;         result := JSON.Load(response)
    ;         ; 处理响应文本
    ;         translatedText := result.choices[1].message.content

    ;         ; 确保输出文本使用正确的编码
    ;         GuiControl,, OutputText, % translatedText
    ;     } catch e {
    ;         MsgBox, 16, 错误, 解析响应失败：`n%e%
    ;         GuiControl,, OutputText, 处理响应时出错，请检查API设置是否正确
    ;     }
    ; }
}

; HTTP请求函数
HttpGet(url, token) {
    whr := ComObjCreate("WinHttp.WinHttpRequest.5.1")
    whr.SetTimeouts(30000, 30000, 30000, 1200000)
    whr.Open("GET", url, true)
    whr.SetRequestHeader("Authorization", "Bearer " token)
    whr.Send()
    whr.WaitForResponse()
    return whr.ResponseText
}

HttpPost(url, token, sendData) {
    ToolTip, AI请求中
    try {
        whr := ComObjCreate("WinHttp.WinHttpRequest.5.1")
        ; 设置超时时间(毫秒): 解析域名超时, 连接超时, 发送超时, 接收超时
        whr.SetTimeouts(30000, 30000, 30000, 1200000)
        whr.Open("POST", url, true)
        whr.SetRequestHeader("Authorization", "Bearer " token)
        whr.SetRequestHeader("Content-Type", "application/json")

        whr.Send(sendData)
        whr.WaitForResponse()

        if (whr.Status != 200) {
            throw Exception("API请求失败，状态码：" whr.Status "`n响应：" whr.ResponseText)
        }
        response := byteToStr(whr.ResponseBody, "utf-8")
        ToolTip
        return response
    } catch e {
        ToolTip
        MsgBox, 16, 错误, API请求失败, 请检查api设置：`n%e%
        return ""
    }
}

;将原始数据流以指定的编码的形式读出
byteToStr(body, charset){
    Stream := ComObjCreate("Adodb.Stream")
    Stream.Type := 1
    Stream.Mode := 3
    Stream.Open()
    Stream.Write(body)
    Stream.Position := 0
    Stream.Type := 2
    Stream.Charset := charset
    str := Stream.ReadText()
    Stream.Close()
    return str
}

listRemove(promptOrder, removeValue){
    for index, element in promptOrder
    {
        if (element == removeValue) {
            promptOrder.RemoveAt(index)
            break
        }
    }
}

; API设置窗口
ButtonSettings:
    Gui, Settings:New, +Owner
    Gui, Settings:Font, s10, Microsoft YaHei

    ; 从局变量加载现有配置
    global apiUrl, apiKey, selectedModel, modelList

    Gui, Settings:Add, Text,, API地址:

    apiUrlList := "https://api.deepseek.com|https://api.siliconflow.cn"
    ; 如果当前 apiUrl 不在列表中，添加到列表开头
    if (!InStr(apiUrlList, apiUrl))
        apiUrlList := apiUrl "|" apiUrlList
    Gui, Settings:Add, ComboBox, vApiUrl w300, % apiUrlList
    ; 设置当前选中的 API 地址
    GuiControl, Settings:Choose, ApiUrl, % apiUrl

    Gui, Settings:Add, Text,, API密钥:
    Gui, Settings:Add, Edit, vApiKey w300, % apiKey

    Gui, Settings:Add, Text,, 模型:
    ; 如果modelList为，则使用当前选中的模型作为默认值
    if (modelList = "")
        modelList := selectedModel
    Gui, Settings:Add, ComboBox, vSelectedModel w300, % modelList
    ; 设置当前选中的模型
    GuiControl, Settings:Choose, SelectedModel, % selectedModel

    Gui, Settings:Add, Button, gGetModels w100, 获取可用模型
    Gui, Settings:Add, Button, x+10 gSaveSettings w100, 保存设置

    Gui, Settings:Show, AutoSize, API设置
return

GetModels:
    Gui, Settings:Submit, NoHide  ; 获取当前输入的API设置但不关闭窗口

    ; 使用当前输入的API设置获取模型列表
    try {
        response := HttpGet(ApiUrl "/v1/models", ApiKey)
        models := JSON.Load(response)

        ; 更新模型列表
        global modelList := ""
        Loop % models.data.Length()
            modelList .= models.data[A_Index].id "|"

        ; 更新ComboBox并保持当前选择
        GuiControl, Settings:, SelectedModel, |%modelList%
        if (SelectedModel)
            GuiControl, Settings:Choose, SelectedModel, %SelectedModel%
    } catch e {
        MsgBox, 16, 错误, 获取模型列表失败：`n%e%
    }
return

SaveSettings:
    Gui, Settings:Submit

    ; 更新全局变量
    global apiUrl := ApiUrl
    global apiKey := ApiKey
    global selectedModel := SelectedModel
    ; 保存配置到文件
    IniWrite, %ApiUrl%, config.ini, API, apiUrl
    IniWrite, %ApiKey%, config.ini, API, apiKey
    IniWrite, %selectedModel%, config.ini, API, selectedModel
    IniWrite, %modelList%, config.ini, API, availableModels

    Gui, Settings:Destroy
return

ButtonPrompt:
    ; 创建Prompt选择窗口
    Gui, Prompt:New, +Owner
    Gui, Prompt:Font, s10, Microsoft YaHei

    Gui, Prompt:Add, ListBox, vSelectedPrompt gPromptListBoxHandler w400 h300, % promptList
    Gui, Prompt:Add, Button, x10 y+10 w80 gSelectPrompt, 选择
    Gui, Prompt:Add, Button, x+10 w80 gAddPrompt, 新增
    Gui, Prompt:Add, Button, x+10 w80 gEditPrompt, 修改
    Gui, Prompt:Add, Button, x+10 w80 gDeletePrompt, 删除

    Gui, Prompt:Show, , 选择Prompt
return

; 添加 ListBox 双击处理函数
PromptListBoxHandler:
    if (A_GuiEvent = "DoubleClick")
        Gosub, EditPrompt
return

; 添加新的 Prompt
AddPrompt:
    Gui, AddPrompt:New, +Owner
    Gui, AddPrompt:Font, s10, Microsoft YaHei

    Gui, AddPrompt:Add, Text,, Prompt名称:
    Gui, AddPrompt:Add, Edit, vPromptName w300
    Gui, AddPrompt:Add, Text,, Prompt内容:
    Gui, AddPrompt:Add, Edit, vPromptContent w%promptWidth% h%promptHeight% Multi  ; 添加 Multi 选项支持多行
    Gui, AddPrompt:Add, Button, gAddNewPrompt w100, 保存

    Gui, AddPrompt:Show, , 新增Prompt
return

AddNewPrompt:
    Gui, AddPrompt:Submit
    if (PromptName && PromptContent) {
        if(promptMap[PromptName]) {
            MsgBox, % "已经存在prompt: " PromptName
            Return
        }
        ; 处理换行符，将实际换行符转换为 \n
        PromptContent := RegExReplace(PromptContent, "\r\n|\n|\r", "\n")
        IniWrite, %PromptContent%, config.ini, Prompts, %PromptName%
        promptMap[PromptName] := PromptContent
        promptOrder.Push(PromptName)  ; 将新键添加到数组中
        ;print(promptMap, promptOrder)
        ; 更新 promptList
        promptList .= "|" PromptName
        GuiControl, Prompt:, SelectedPrompt, |%promptList%
    }
    Gui, AddPrompt:Destroy
return

; 修改选中的 Prompt
EditPrompt:
    Gui, Prompt:Submit, NoHide
    if (!SelectedPrompt) {
        MsgBox, 请先选择要修改的Prompt
        return
    }
    currentContent := promptMap[SelectedPrompt]
    ; 将存储的 \n 转换回实际的换行符
    currentContent := RegExReplace(currentContent, "\\n", "`n")

    Gui, EditPrompt:New, +Owner
    Gui, EditPrompt:Font, s10, Microsoft YaHei

    Gui, EditPrompt:Add, Text,, Prompt名称:
    Gui, EditPrompt:Add, Edit, vNewPromptName w300, %SelectedPrompt%
    Gui, EditPrompt:Add, Text,, Prompt内容:
    Gui, EditPrompt:Add, Edit, vNewPromptContent w%promptWidth% h%promptHeight% Multi, %currentContent%  ; 添加 Multi 选项支持多行
    Gui, EditPrompt:Add, Button, gUpdateEditPrompt w100, 保存

    Gui, EditPrompt:Show,, 修改Prompt
return

UpdateEditPrompt:
    Gui, EditPrompt:Submit
    if (NewPromptName && NewPromptContent) {
        ; 处理换行符，将实际换行符转换为 \n
        NewPromptContent := RegExReplace(NewPromptContent, "\r\n|\n|\r", "\n")
        ; TODO 不处理新prompt覆盖老的情况, 如果要处理需要在添加listbox的时候加上 +AltSubmit, 传递SelectedPrompt为下标
        ; 如果名称改变，删除旧的
        if (NewPromptName != SelectedPrompt) {
            IniDelete, config.ini, Prompts, %SelectedPrompt%
            listRemove(promptOrder, SelectedPrompt)
            promptMap.Remove(SelectedPrompt)
            promptOrder.Push(NewPromptName)  ; 将新键添加到数组中
        }

        IniWrite, %NewPromptContent%, config.ini, Prompts, %NewPromptName%
        promptMap[NewPromptName] := NewPromptContent

        ;print(promptMap, promptOrder)
        ; 重新加载 promptList
        promptList := ""
        for index, promptName in promptOrder {
            promptList .= promptName "|"
        }

        GuiControl, Prompt:, SelectedPrompt, |%promptList%
    }
    Gui, EditPrompt:Destroy
return

; 删除选中的 Prompt
DeletePrompt:
    Gui, Prompt:Submit, NoHide
    if (!SelectedPrompt) {
        MsgBox, 请先选择要删除的Prompt
        return
    }

    MsgBox, 4, 确认删除, 确定要删除 %SelectedPrompt% 吗？
    IfMsgBox Yes
    {
        IniDelete, config.ini, Prompts, %SelectedPrompt%
        promptMap.Remove(SelectedPrompt)
        listRemove(promptOrder, SelectedPrompt)
        ;print(promptMap, promptOrder)
        ; 重新加载 promptList
        promptList := ""
        for idx, promptName in promptOrder {
            promptList .= promptName "|"
        }

        GuiControl, Prompt:, SelectedPrompt, |%promptList%
        ;如果删除的是当前选中的prompt, 更新SelectedPromptText为 Default
        GuiControlGet, currentPromptText, Main:, SelectedPromptText
        if (SelectedPrompt == currentPromptText) {
            GuiControl, Main:, SelectedPromptText, Default
            sysPrompt = promptMap["Default"]
        }
    }
return

; 修改 SelectPrompt 函数
SelectPrompt:
    Gui, Prompt:Submit
    if (SelectedPrompt) {
        global sysPrompt := promptMap[SelectedPrompt]
        ; 保存 SelectedPrompt 为默认值
        IniWrite, %SelectedPrompt%, config.ini, Defaults, SelectedPrompt
        ; 更新显示的prompt名称
        GuiControl, Main:, SelectedPromptText, %SelectedPrompt%
    }
    Gui, Prompt:Destroy
return

; 添加新的关闭处理函数
AddPromptGuiClose:
AddPromptGuiEscape:
    Gui, AddPrompt:Destroy
return

EditPromptGuiClose:
EditPromptGuiEscape:
    Gui, EditPrompt:Destroy
return

ButtonQuick:
    Gui, Main:Submit, NoHide
    ControlGetText, ButtonText, %A_GuiControl%, A
    btnPrompt := promptMap[ButtonText]
    if(!btnPrompt) {
        MsgBox, prompt提示词不存在, 可能已被删除
    }
    sendRequest(btnPrompt, InputText)
return

ButtonSend:
    Gui, Main:Submit, NoHide
    ; 根据不同按钮设置不同的系统提示
    sendRequest(sysPrompt, InputText)
return

PromptGuiClose:
PromptGuiEscape:
    Gui, Prompt:Destroy
return

ButtonTranslate:
    ; 添加这行来获取最新的控件值
    Gui, Main:Submit, NoHide
    btnPrompt := "下面我让你来充当翻译家，你的目标是把任何语言翻译成中文，请翻译时不要带翻译腔，而是要翻译得自然、流畅和地道，使用优美和高雅的表达方式。"
    userPrompt := "翻译下面内容:``````" InputText "``````"
    sendRequest(btnPrompt, userPrompt)
return

; 其他按钮处理...

SettingsGuiClose:
SettingsGuiEscape:
    Gui, Settings:Destroy
return

; 在 MainGuiClose 标签之前添加窗口大小保存函数
SaveWindowSizes() {
    ; 获取窗口位置和大小
    WinGetPos,,, actualWidth, actualHeight, %mainName%

    ; 保存实际的窗口大小（包含边框和标题栏）
    IniWrite, %actualWidth%, config.ini, WindowSize, mainWidth
    IniWrite, %actualHeight%, config.ini, WindowSize, mainHeight
}

; 修改主窗口关闭处理
MainGuiClose:
    SaveWindowSizes()
ExitApp

; 在 return 之前添加窗口大小调整事件处理
MainGuiSize:
    if (A_EventInfo = 1)  ; 窗口被最小化
        return

    ; 获取新的窗口大小
    newWidth := A_GuiWidth
    newHeight := A_GuiHeight

    ; 计算调整后的宽度（考虑边距）
    adjustedWidth := newWidth - 30

    ; 调整输入框宽度
    GuiControl, Move, InputText, w%adjustedWidth%

    ; 计算输出框的新高度（总高度减去其他控件的高度和边距）
    outputHeight := newHeight - 300  ; 300是其他控件和边距的总高度
    if (outputHeight < 300)  ; 设置最小高度
        outputHeight := 300

    ; 调整输出框的大小和位置
    GuiControl, Move, OutputText, w%adjustedWidth% h%outputHeight%

    ; 计算设置API和发送按钮的位置
    settingsButtonX := adjustedWidth - 80 -80 - 10
    sendButtonX := settingsButtonX + 85

    ; 移动按钮
    GuiControl, Move, 设置API, x%settingsButtonX%
    GuiControl, Move, 发送, x%sendButtonX%

    ; 只在用户手动调整窗口大小时保存
    SaveWindowSizes()
return

SettingsGuiSize:
    if (A_EventInfo = 1)  ; 窗口被最小化
        return
    if (A_EventInfo = 0)  ; 窗口被还原
        return
    ; 只在用户手动调整窗口大小时保存
    SaveWindowSizes()
return

PromptGuiSize:
    if (A_EventInfo = 1)  ; 窗口被最小化
        return
    if (A_EventInfo = 0)  ; 窗口被还原
        return
    ; 只在用户手动调整窗口大小时保存
    SaveWindowSizes()
return
