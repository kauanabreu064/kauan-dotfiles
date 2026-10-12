hl.config({
	input = {
		kb_layout = "br",
		kb_model = "abnt2"
	},
})

hl.bind(
    "SUPER + SHIFT + S",
    hl.dsp.exec_cmd("/home/kauan/.local/bin/screenshot-area")
)

-- Spotify
hl.bind(
    "SUPER + SHIFT + T",
    hl.dsp.exec_cmd("spotify")
)

-- Color picker -> copia HEX
hl.bind(
    "SUPER + SHIFT + C",
    hl.dsp.exec_cmd("hyprpicker -a")
)

-- Recarregar Hyprland
hl.bind(
    "SUPER + SHIFT + R",
    hl.dsp.exec_cmd("hyprctl reload")
)

-- =========================
-- ANIMAÇÕES CUSTOM
-- =========================

hl.curve("kauanEase", {
    type = "bezier",
    points = {
        {0.22, 1},
        {0.36, 1},
    },
})

hl.curve("kauanFast", {
    type = "bezier",
    points = {
        {0.15, 0},
        {0.1, 1},
    },
})

hl.animation({
    leaf = "windowsIn",
    enabled = true,
    speed = 4.5,
    bezier = "kauanEase",
    style = "popin 92%",
})

hl.animation({
    leaf = "windowsOut",
    enabled = true,
    speed = 3.0,
    bezier = "kauanFast",
    style = "popin 94%",
})

hl.animation({
    leaf = "fade",
    enabled = true,
    speed = 3.5,
    bezier = "kauanFast",
})

hl.animation({
    leaf = "workspaces",
    enabled = true,
    speed = 3.5,
    bezier = "kauanEase",
    style = "slide",
})

hl.animation({
    leaf = "layersIn",
    enabled = true,
    speed = 4.0,
    bezier = "kauanEase",
    style = "fade",
})

hl.animation({
    leaf = "layersOut",
    enabled = true,
    speed = 3.0,
    bezier = "kauanFast",
    style = "fade",
})

-- Control Center customizado
hl.bind(
    "SUPER + SHIFT + N",
    hl.dsp.exec_cmd("/home/kauan/.local/bin/control-center")
)
