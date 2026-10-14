# ═══════════ The Drowned Lands — palette v4 ═══════════
# Historical Bronze Age pigments × game mythology × WCAG AA.
#
# Pigments referenced:
#   • Egyptian blue (CaCuSi4O10) — first synthetic pigment, symbol of
#     water, sky, and the Bitter River.
#   • Orpiment (As2S3) — warm gold/yellow, sun and gold.
#   • Hematite ochre (Fe2O3) — blood, war, danger.
#   • Malachite (Cu2CO3(OH)2) — life, Osiris.
#   • Lapis lazuli (Na8-10(Al6Si6O24)S2-4) — rarest pigment, gods,
#     ritual. In game: map fragments.
#   • Deep indigo — storm ring and Tiamat; the drowning world's chaos.
#
# WCAG AA (≥4.5:1) / AAA (≥7:1) computed against COL_NIGHT.

class_name Palette
extends RefCounted

# ─── Surfaces (low → high) ───
const COL_NIGHT        := Color(0.055, 0.075, 0.110, 1.0)
const COL_PANEL        := Color(0.098, 0.128, 0.180, 0.94)
const COL_PANEL_DK     := Color(0.040, 0.058, 0.084, 0.96)

# ─── Borders ───
const COL_BORDER_GOLD  := Color(0.560, 0.440, 0.230, 0.55)

# ─── Text on dark ───
const COL_TEXT     := Color(0.925, 0.930, 0.945, 1.0)   # 15.9:1 AAA
const COL_TEXT_MID := Color(0.820, 0.780, 0.665, 1.0)   # 11.1:1 AAA
const COL_TEXT_DIM := Color(0.615, 0.575, 0.470, 1.0)   #  5.1:1 AA

# ─── Egyptian blue — structure / info / water ───
const COL_BLUE    := Color(0.184, 0.373, 0.525, 1.0)
const COL_BLUE_DK := Color(0.114, 0.243, 0.353, 1.0)
const COL_BLUE_LT := Color(0.420, 0.627, 0.784, 1.0)    #  5.6:1 AA
const COL_FLOOD      := Color(0.215, 0.385, 0.500, 1.0)  # flooded land fill (alpha at call site)
const COL_FLOOD_EDGE := Color(0.305, 0.490, 0.615, 1.0)  # flooded land stroke
const COL_SEA_VOID   := Color(0.150, 0.265, 0.370, 1.0)  # empty-water hex stroke
const COL_SAIL_DK    := Color(0.114, 0.243, 0.353, 1.0)  # sail reach base, low cm
const COL_SAIL_LT    := Color(0.265, 0.590, 0.640, 1.0)  # sail reach base, high cm

# ─── Land — ochre ground, earth, pale rock ───
const COL_LAND_LOW   := Color(0.560, 0.360, 0.200, 1.0)
const COL_LAND_EARTH := Color(0.725, 0.495, 0.288, 1.0)
const COL_LAND_ROCK  := Color(0.865, 0.790, 0.630, 1.0)

# ─── Electrum gold (ἤλεκτρον) — primary / CTA / highlights ───
# Natural gold–silver alloy of the Lydian river Pactolus; first coinage
# (7th c. BCE) and the mythological river of Midas. Bright pale gold.
const COL_GOLD    := Color(0.949, 0.808, 0.353, 1.0)    # 12.5:1 AAA
const COL_GOLD_LT := Color(1.000, 0.933, 0.647, 1.0)    # 14.7:1 AAA
const COL_GOLD_DK := Color(0.769, 0.580, 0.196, 1.0)    #  8.0:1 AAA

# ─── Hematite ochre — danger / death ───
const COL_OCHRE    := Color(0.560, 0.230, 0.165, 1.0)   # pressed states, fragment border
const COL_OCHRE_LT := Color(0.855, 0.480, 0.370, 1.0)   #  6.1:1 AA
const COL_OCHRE_DK := Color(0.362, 0.142, 0.098, 1.0)

# ─── Malachite — success / life / crew ───
const COL_MALACHITE    := Color(0.300, 0.550, 0.358, 1.0)
const COL_MALACHITE_LT := Color(0.500, 0.755, 0.562, 1.0) #  8.8:1 AAA

# ─── Lapis lazuli — rare / ritual / fragments ───
const COL_LAPIS    := Color(0.175, 0.232, 0.550, 1.0)
const COL_LAPIS_LT := Color(0.432, 0.495, 0.800, 1.0)   #  4.7:1 AA

# ─── Tiamat — storm / mythic / chaos ───
const COL_STORM    := Color(0.198, 0.165, 0.400, 1.0)   # deep indigo
const COL_STORM_LT := Color(0.558, 0.510, 0.784, 1.0)   # lit-storm accent, blue-violet
const COL_STORM_DK := Color(0.090, 0.072, 0.165, 1.0)   # storm/tower hex fill

# ─── Materials — shipbuilding (cedar, acacia, cypress, oak, linen) ───
const COL_CEDAR    := Color(0.660, 0.526, 0.354, 1.0)   # hull planking, light
const COL_CEDAR_DK := Color(0.290, 0.166, 0.072, 1.0)   # hull outline, mast
const COL_ACACIA   := Color(0.550, 0.322, 0.188, 1.0)   # depet hull
const COL_CYPRESS  := Color(0.788, 0.730, 0.575, 1.0)   # keftiu hull
const COL_OAK      := Color(0.722, 0.463, 0.228, 1.0)   # deck structures, cabin
const COL_LINEN    := Color(0.955, 0.924, 0.838, 1.0)   # sail cloth
const COL_LINEN_DK := Color(0.200, 0.255, 0.310, 1.0)   # sail edge / rigging

# ─── Overlays ───
const COL_VEIL   := Color(0.0, 0.0, 0.0, 0.60)
const COL_SHADOW := Color(0.0, 0.0, 0.0, 1.0)