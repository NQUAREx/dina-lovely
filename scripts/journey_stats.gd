extends RefCounted
const DEFAULTS:={"steps":0,"distance":0.0,"berries":0,"apples":0,"kills":0,"waterings":0,"blooms":0,"digs":0,"rockets":0,"pets":0,"retries":0,"beds":0}
static func repair(g:Node2D)->void:
 for key in DEFAULTS:
  if not g.save_data.stats.has(key):g.save_data.stats[key]=DEFAULTS[key]
static func add(g:Node2D,key:String,value:float=1)->void:
 repair(g)
 g.save_data.stats[key]=float(g.save_data.stats[key])+value
static func show(g:Node2D)->void:
 repair(g)
 var values:Dictionary=g.save_data.stats.duplicate()
 for key in values:values[key]=str(int(values[key]))
 values.tiles=str(int(float(g.save_data.stats.distance)/48))
 values.letters=str(g.save_data.letters.size());values.gates=str(g.save_data.open_gates.size())
 values.cat=g.tx("stats_cat_yes" if g.save_data.cat_tamed else "stats_cat_no")
 g.show_text_page(g.tx("stats_title"),g.tx("stats_body").format(values))
