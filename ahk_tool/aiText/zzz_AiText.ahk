;************************
;* 【ai处理文本工具】
;************************
global RunAny_Plugins_Version:="1.0.0"
#NoTrayIcon             ;~不显示托盘图标
#Persistent             ;~让脚本持久运行
#SingleInstance,Force   ;~运行替换旧实例
;********************************************************************************
#Include %A_ScriptDir%\..\RunAny_ObjReg.ahk
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
promptMap["Default"] = "你是工作助手"

; 读取配置
LoadConfig()

Return


class RunAnyObj {
    ;[新建：你自己的函数]
    ;保存到RunAny.ini为：菜单项名|你的脚本文件名zzz_AiText[你的函数名](参数1,参数2)
    ;你的函数名(参数1,参数2){
    ;函数内容写在这里

    ;}
    dotask(getZz:="", sysPromptIn:=""){
        createGui()
        setInput(getZz, sysPromptIn)
    }
    ;══════════════════════════大括号以上是RunAny菜单调用的函数══════════════════════════

}

;═══════════════════════════以下是脚本自己调用依赖的函数═══════════════════════════

createGui(){
    
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
    {
        if(addBtn > 2) {
            break
        }
        if(promptName == "翻译" || promptName == "Default") {
            Continue
        } else {
            Gui, Main:Add, Button, x+5 w80 h30 gButtonQuick, %promptName%
            addBtn += 1
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
}

setInput(getZz:="", sysPromptIn:=""){
    ;print(getZz, sysPromptIn)
    if(getZz) {
        if(sysPromptIn && promptMap[sysPromptIn]) {
            sysPrompt := promptMap[sysPromptIn]
        }
        GuiControl, Main:, InputText, %getZz%
        Gosub, ButtonSend
        ; sendRequest(sysPrompt, InputText)
    }
}


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
    theUserPrompt := RegExReplace(theUserPrompt, """", "\""")  
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
    HttpPost(apiUrl "/v1/chat/completions", apiKey, sendData)


    response := HttpPost(apiUrl "/v1/chat/completions", apiKey, sendData)

    if (response) {  ; 只在有响应时处
        try {
            result := JSON.Load(response)
            ; 处理响应文本
            translatedText := result.choices[1].message.content

            ; 确保输出文本使用正确的编码
            GuiControl,, OutputText, % translatedText
        } catch e {
            MsgBox, 16, 错误, 解析响应失败：`n%e%
            GuiControl,, OutputText, 处理响应时出错，请检查API设置是否正确
        }
    }
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


HttpPostStream(url, token, sendData, callback) {
    ; 创建 WinHTTP 对象
    whr := ComObjCreate("WinHttp.WinHttpRequest.5.1")
    
    ; 配置请求
    whr.Open("POST", url, true) ; true 表示异步
    whr.SetRequestHeader("Content-Type", "application/json; charset=utf-8")
    whr.SetRequestHeader("Authorization", "Bearer " token)
    ; 设置响应类型为流
    whr.Option(6) := false ; 禁用自动重定向
    whr.SetTimeouts(0, 60000, 30000, 0) ; 设置超时
    
    ; 发送请求
    whr.Send(postData)
    
    ; 等待响应开始
    whr.WaitForResponse(0)
    
    ; 获取响应流
    stream := whr.ResponseStream
    text := ""
    
    ; 读取缓冲区
    buffer := ComObjArray(0x11, 8192) ; VT_ARRAY | VT_UI1
    
    ; 循环读取响应流
    while true {
        translatedText := ""
        ; 读取数据到缓冲区
        bytesRead := stream.Read(buffer, 8192)
        
        if (bytesRead = 0) ; 读取完成
            break
            
        ; 转换缓冲区数据为文本
        loop % bytesRead {
            text .= Chr(buffer[A_Index - 1])
        }
        ; 调用回调函数处理当前文本块
        GuiControl,, OutputText, % text
    }
    
    return
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
    Gui, Main:Destroy
return

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

class JSON
{
	/**
	 * Method: Load
	 *     Parses a JSON string into an AHK value
	 * Syntax:
	 *     value := JSON.Load( text [, reviver ] )
	 * Parameter(s):
	 *     value      [retval] - parsed value
	 *     text    [in, ByRef] - JSON formatted string
	 *     reviver   [in, opt] - function object, similar to JavaScript's
	 *                           JSON.parse() 'reviver' parameter
	 */
	class Load extends JSON.Functor
	{
		Call(self, ByRef text, reviver:="")
		{
			this.rev := IsObject(reviver) ? reviver : false
		; Object keys(and array indices) are temporarily stored in arrays so that
		; we can enumerate them in the order they appear in the document/text instead
		; of alphabetically. Skip if no reviver function is specified.
			this.keys := this.rev ? {} : false

			static quot := Chr(34), bashq := "\" . quot
			     , json_value := quot . "{[01234567890-tfn"
			     , json_value_or_array_closing := quot . "{[]01234567890-tfn"
			     , object_key_or_object_closing := quot . "}"

			key := ""
			is_key := false
			root := {}
			stack := [root]
			next := json_value
			pos := 0

			while ((ch := SubStr(text, ++pos, 1)) != "") {
				if InStr(" `t`r`n", ch)
					continue
				if !InStr(next, ch, 1)
					this.ParseError(next, text, pos)

				holder := stack[1]
				is_array := holder.IsArray

				if InStr(",:", ch) {
					next := (is_key := !is_array && ch == ",") ? quot : json_value

				} else if InStr("}]", ch) {
					ObjRemoveAt(stack, 1)
					next := stack[1]==root ? "" : stack[1].IsArray ? ",]" : ",}"

				} else {
					if InStr("{[", ch) {
					; Check if Array() is overridden and if its return value has
					; the 'IsArray' property. If so, Array() will be called normally,
					; otherwise, use a custom base object for arrays
						static json_array := Func("Array").IsBuiltIn || ![].IsArray ? {IsArray: true} : 0
					
					; sacrifice readability for minor(actually negligible) performance gain
						(ch == "{")
							? ( is_key := true
							  , value := {}
							  , next := object_key_or_object_closing )
						; ch == "["
							: ( value := json_array ? new json_array : []
							  , next := json_value_or_array_closing )
						
						ObjInsertAt(stack, 1, value)

						if (this.keys)
							this.keys[value] := []
					
					} else {
						if (ch == quot) {
							i := pos
							while (i := InStr(text, quot,, i+1)) {
								value := StrReplace(SubStr(text, pos+1, i-pos-1), "\\", "\u005c")

								static tail := A_AhkVersion<"2" ? 0 : -1
								if (SubStr(value, tail) != "\")
									break
							}

							if (!i)
								this.ParseError("'", text, pos)

							  value := StrReplace(value,  "\/",  "/")
							, value := StrReplace(value, bashq, quot)
							, value := StrReplace(value,  "\b", "`b")
							, value := StrReplace(value,  "\f", "`f")
							, value := StrReplace(value,  "\n", "`n")
							, value := StrReplace(value,  "\r", "`r")
							, value := StrReplace(value,  "\t", "`t")

							pos := i ; update pos
							
							i := 0
							while (i := InStr(value, "\",, i+1)) {
								if !(SubStr(value, i+1, 1) == "u")
									this.ParseError("\", text, pos - StrLen(SubStr(value, i+1)))

								uffff := Abs("0x" . SubStr(value, i+2, 4))
								if (A_IsUnicode || uffff < 0x100)
									value := SubStr(value, 1, i-1) . Chr(uffff) . SubStr(value, i+6)
							}

							if (is_key) {
								key := value, next := ":"
								continue
							}
						
						} else {
							value := SubStr(text, pos, i := RegExMatch(text, "[\]\},\s]|$",, pos)-pos)

							static number := "number", integer :="integer"
							if value is %number%
							{
								if value is %integer%
									value += 0
							}
							else if (value == "true" || value == "false")
								value := %value% + 0
							else if (value == "null")
								value := ""
							else
							; we can do more here to pinpoint the actual culprit
							; but that's just too much extra work.
								this.ParseError(next, text, pos, i)

							pos += i-1
						}

						next := holder==root ? "" : is_array ? ",]" : ",}"
					} ; If InStr("{[", ch) { ... } else

					is_array? key := ObjPush(holder, value) : holder[key] := value

					if (this.keys && this.keys.HasKey(holder))
						this.keys[holder].Push(key)
				}
			
			} ; while ( ... )

			return this.rev ? this.Walk(root, "") : root[""]
		}

		ParseError(expect, ByRef text, pos, len:=1)
		{
			static quot := Chr(34), qurly := quot . "}"
			
			line := StrSplit(SubStr(text, 1, pos), "`n", "`r").Length()
			col := pos - InStr(text, "`n",, -(StrLen(text)-pos+1))
			msg := Format("{1}`n`nLine:`t{2}`nCol:`t{3}`nChar:`t{4}"
			,     (expect == "")     ? "Extra data"
			    : (expect == "'")    ? "Unterminated string starting at"
			    : (expect == "\")    ? "Invalid \escape"
			    : (expect == ":")    ? "Expecting ':' delimiter"
			    : (expect == quot)   ? "Expecting object key enclosed in double quotes"
			    : (expect == qurly)  ? "Expecting object key enclosed in double quotes or object closing '}'"
			    : (expect == ",}")   ? "Expecting ',' delimiter or object closing '}'"
			    : (expect == ",]")   ? "Expecting ',' delimiter or array closing ']'"
			    : InStr(expect, "]") ? "Expecting JSON value or array closing ']'"
			    :                      "Expecting JSON value(string, number, true, false, null, object or array)"
			, line, col, pos)

			static offset := A_AhkVersion<"2" ? -3 : -4
			throw Exception(msg, offset, SubStr(text, pos, len))
		}

		Walk(holder, key)
		{
			value := holder[key]
			if IsObject(value) {
				for i, k in this.keys[value] {
					; check if ObjHasKey(value, k) ??
					v := this.Walk(value, k)
					if (v != JSON.Undefined)
						value[k] := v
					else
						ObjDelete(value, k)
				}
			}
			
			return this.rev.Call(holder, key, value)
		}
	}

	/**
	 * Method: Dump
	 *     Converts an AHK value into a JSON string
	 * Syntax:
	 *     str := JSON.Dump( value [, replacer, space ] )
	 * Parameter(s):
	 *     str        [retval] - JSON representation of an AHK value
	 *     value          [in] - any value(object, string, number)
	 *     replacer  [in, opt] - function object, similar to JavaScript's
	 *                           JSON.stringify() 'replacer' parameter
	 *     space     [in, opt] - similar to JavaScript's JSON.stringify()
	 *                           'space' parameter
	 */
	class Dump extends JSON.Functor
	{
		Call(self, value, replacer:="", space:="")
		{
			this.rep := IsObject(replacer) ? replacer : ""

			this.gap := ""
			if (space) {
				static integer := "integer"
				if space is %integer%
					Loop, % ((n := Abs(space))>10 ? 10 : n)
						this.gap .= " "
				else
					this.gap := SubStr(space, 1, 10)

				this.indent := "`n"
			}

			return this.Str({"": value}, "")
		}

		Str(holder, key)
		{
			value := holder[key]

			if (this.rep)
				value := this.rep.Call(holder, key, ObjHasKey(holder, key) ? value : JSON.Undefined)

			if IsObject(value) {
			; Check object type, skip serialization for other object types such as
			; ComObject, Func, BoundFunc, FileObject, RegExMatchObject, Property, etc.
				static type := A_AhkVersion<"2" ? "" : Func("Type")
				if (type ? type.Call(value) == "Object" : ObjGetCapacity(value) != "") {
					if (this.gap) {
						stepback := this.indent
						this.indent .= this.gap
					}

					is_array := value.IsArray
				; Array() is not overridden, rollback to old method of
				; identifying array-like objects. Due to the use of a for-loop
				; sparse arrays such as '[1,,3]' are detected as objects({}). 
					if (!is_array) {
						for i in value
							is_array := i == A_Index
						until !is_array
					}

					str := ""
					if (is_array) {
						Loop, % value.Length() {
							if (this.gap)
								str .= this.indent
							
							v := this.Str(value, A_Index)
							str .= (v != "") ? v . "," : "null,"
						}
					} else {
						colon := this.gap ? ": " : ":"
						for k in value {
							v := this.Str(value, k)
							if (v != "") {
								if (this.gap)
									str .= this.indent

								str .= this.Quote(k) . colon . v . ","
							}
						}
					}

					if (str != "") {
						str := RTrim(str, ",")
						if (this.gap)
							str .= stepback
					}

					if (this.gap)
						this.indent := stepback

					return is_array ? "[" . str . "]" : "{" . str . "}"
				}
			
			} else ; is_number ? value : "value"
				return ObjGetCapacity([value], 1)=="" ? value : this.Quote(value)
		}

		Quote(string)
		{
			static quot := Chr(34), bashq := "\" . quot

			if (string != "") {
				  string := StrReplace(string,  "\",  "\\")
				; , string := StrReplace(string,  "/",  "\/") ; optional in ECMAScript
				, string := StrReplace(string, quot, bashq)
				, string := StrReplace(string, "`b",  "\b")
				, string := StrReplace(string, "`f",  "\f")
				, string := StrReplace(string, "`n",  "\n")
				, string := StrReplace(string, "`r",  "\r")
				, string := StrReplace(string, "`t",  "\t")

				static rx_escapable := A_AhkVersion<"2" ? "O)[^\x20-\x7e]" : "[^\x20-\x7e]"
				while RegExMatch(string, rx_escapable, m)
					string := StrReplace(string, m.Value, Format("\u{1:04x}", Ord(m.Value)))
			}

			return quot . string . quot
		}
	}

	/**
	 * Property: Undefined
	 *     Proxy for 'undefined' type
	 * Syntax:
	 *     undefined := JSON.Undefined
	 * Remarks:
	 *     For use with reviver and replacer functions since AutoHotkey does not
	 *     have an 'undefined' type. Returning blank("") or 0 won't work since these
	 *     can't be distnguished from actual JSON values. This leaves us with objects.
	 *     Replacer() - the caller may return a non-serializable AHK objects such as
	 *     ComObject, Func, BoundFunc, FileObject, RegExMatchObject, and Property to
	 *     mimic the behavior of returning 'undefined' in JavaScript but for the sake
	 *     of code readability and convenience, it's better to do 'return JSON.Undefined'.
	 *     Internally, the property returns a ComObject with the variant type of VT_EMPTY.
	 */
	Undefined[]
	{
		get {
			static empty := {}, vt_empty := ComObject(0, &empty, 1)
			return vt_empty
		}
	}

	class Functor
	{
		__Call(method, ByRef arg, args*)
		{
		; When casting to Call(), use a new instance of the "function object"
		; so as to avoid directly storing the properties(used across sub-methods)
		; into the "function object" itself.
			if IsObject(method)
				return (new this).Call(method, arg, args*)
			else if (method == "")
				return (new this).Call(arg, args*)
		}
	}
}