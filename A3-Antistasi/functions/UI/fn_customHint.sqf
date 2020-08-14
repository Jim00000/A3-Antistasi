/*
Function:
    A3A_fnc_customHint

Description:
    Adds item to hint queue.
    Set enableDismissibleHints=false to use original custom hint.
    Using Dismissible Hint runs 7x faster than regular customHint. (see benchmarks by EOF.).

Scope:
    <LOCAL> Execute on each player to add a global notification.

Environment:
    <UNSCHEDULED> Simultaneous modification may cause trampling of items in customHintQueue.

Parameters:
    <STRING> Heading of your message.
    <STRING> Body of your message. | <TEXT> The hint will only be body + footer.
    <BOOLEAN> Silent Notification, false if you want to annoy players. [DEFAULT=false]
    <XML IMG> Icon [DEFAULT=A3A Blood Logo,size 2]

Returns:
    <BOOLEAN> true if it hasn't crashed; false if it does not have an interface; nil if it has crashed.

Examples:
    ["FooBar", "Hello World"] call A3A_fnc_customHint;
    ["FooBar", "Hello World"] remoteExec ["A3A_fnc_customHint", 0, false];
    ["Vaya...", "Parece que sus notificaciones importantes se cifraron.<br/><br/>Nadie espera el cifrado español.", false, "<img color='#ffffff' image='Pictures\Intel\laptop_error.paa' align='center' size='6' />"] remoteExec ["A3A_fnc_customHint", 0, false];
    ["Unseen header", parseText "<t size='1.2' color='#e5b348' shadow='1' shadowColor='#000000'>Pre-parsed Example</t><br/><br/><img image='Pictures\Intel\laptop_complete.paa' align='center' size='8'/><br/><br/><t size='1' color='#ffffff' shadow='1' shadowColor='#000000'>Hello World</t><br/>",false] remoteExec ["A3A_fnc_customHint", 0, false];

    // Pre-parse FooBar(Hello World)
        private _iconXML = "<img color='#ffffff' image='functions\UI\images\logo.paa' align='center' size='2' />";
        private _separator  = parseText "<br/><img color='#ffffff' image='functions\UI\images\img_line_ca.paa' align='center' size='0.60' />";
        private _header = parseText "<br/><br/><t size='1.2' color='#e5b348' shadow='1' shadowColor='#000000'>FooBar</t>";
        private _body = parseText "<br/><br/><t size='1' color='#ffffff' shadow='1' shadowColor='#000000'>Hello World</t><br/>";
        FooBarParse = composeText [parseText _iconXML, _header, _separator, _body, _separator];
        ["FooBar", FooBarParse] call A3A_fnc_customHint;

Authors: Michael Phillips(original customHint), Caleb Serafin
License: MIT License, Copyright (c) 2019 Barbolani & The Official AntiStasi Community
*/
params [
    ["_headerText", "", [""]],
    ["_bodyText", "", ["",parseText""]],
    ["_isSilent", false, [false]],
    ["_iconXML", "<img color='#ffffff' image='functions\UI\images\logo.paa' align='center' size='2' />", [""]]
];
private _filename = "fn_customHint.sqf";

if (!hasInterface) exitWith {false;}; // Disabled for server & HC.

private _structuredText = parseText"";
if (_bodyText isEqualType parseText"") then {
    _structuredText = composeText [_bodyText];
} else {
    private _separator  = parseText "<br/><img color='#ffffff' image='functions\UI\images\img_line_ca.paa' align='center' size='0.60' />";
    private _header = parseText (["<br/><br/><t size='1.2' color='#e5b348' shadow='1' shadowColor='#000000'>",_headerText,"</t>"]joinString "");
    private _body = parseText (["<br/><br/><t size='1' color='#ffffff' shadow='1' shadowColor='#000000'>",_bodyText,"</t><br/>"] joinString "");
    _structuredText = composeText [parseText _iconXML, _header, _separator, _body, _separator];
};

if (enableDismissibleHints) then {
    private _index = customHintQueue findIf {(_x #0) isEqualTo _headerText}; // Temporary solution until an programming-interface is added for counters and timers.
    if (_index isEqualTo -1) then {
        customHintQueue pushBack [_headerText,_structuredText,_isSilent];
    } else {
        customHintQueue set [_index,[_headerText,_structuredText,_isSilent]];
    };
    [] call A3A_fnc_renderHint; // Allows immediate display of new hint without waiting for loop.
} else {
    if (_isSilent) then {
        hintSilent _structuredText;
    } else {
        hint _structuredText;
    };
};
true;

/*
// Benchmarks. // TL:DR: short pre-parsed notifications can achieve ludicrous speed.
    // 14 Aug 2020
FooBar (Hello World): customHint(0.745156 ms), NotTop-DismissibleHint(0.673401 ms), NotTop-PreParsed-DismissibleHint(0.670241 ms), DismissibleHint(0.664452 ms), PreParsed-DismissibleHint(0.10421 ms) // Speed lost probably due to queueCheck. Yes, 0.10421 ms.
BeeMovieScript (cut < 8kb): customHint(8.7807 ms), DismissibleHint(8.48305 ms), PreParsed-DismissibleHint(7.54887 ms), NotTop-DismissibleHint(0.676133 ms), NotTop-PreParsed-DismissibleHint(0.670241 ms) // Speed lost due to rendering.
    // 15 Aug 2020
FooBar (Hello World): NotTop-DismissibleHint(0.292826 ms), DismissibleHint(0.282885 ms), InstantHint(0.200602 ms), NotTop-PreParsed-DismissibleHint(0.110779 ms), PreParsed-DismissibleHint(0.102512 ms), PreParsed-InstantHint(0.0334 ms) // Better text render led to x22 performance for customHint.
// TODO: remove all `hintSilent ""` used in boot processes.
*/
