extends SceneTree
var g
func _initialize():call_deferred('run')
func run():
 g=load('res://main.tscn').instantiate();root.add_child(g);await process_frame;g.new_game();g.clear_modal();g.sound_on=false
 assert(g.content.schema_version==2 and not g.tx('read_letter').is_empty() and g.tx('missing_key').is_empty());print('PASS semantic text keys without fallback')
 var order=g.save_data.riddle_order.duplicate();var clues=g.save_data.riddle_clues.duplicate();clues.sort();assert(clues==range(7));assert(order.size()==7)
 for room in range(7):
  var selected=g.save_data.riddle_letters[room];assert(selected in g.content.puzzle.room_letters[room]);var count=0
  for letter in g.content.letters:
   var result=g.letter_with_clue(letter)
   if str(result.text)!=str(letter.text) and letter.id in g.content.puzzle.room_letters[room]:count+=1
  assert(count==1 and not g.riddle_clue(room).is_empty())
 var next={};var first=''
 for room in range(7):
  var i=int(g.save_data.riddle_clues[room])
  if i==0:first=order[0]
  else:next[order[i-1]]=order[i]
 var rebuilt=[first]
 while next.has(rebuilt[-1]):
  assert(rebuilt.size()<7);rebuilt.append(next[rebuilt[-1]])
 assert(rebuilt==order and next.size()==6);print('PASS exactly one solution from seven shuffled room clues')
 g.ensure_riddle();assert(g.save_data.riddle_order==order);g.persist();g.load_save();g.ensure_riddle();assert(g.save_data.riddle_order==order);print('PASS saved answer and clues')
 g.build_level(6);assert(g.objects.filter(func(o):return o.kind=='stone' and o.id in g.content.puzzle.symbols).size()==7);assert(g.objects.any(func(o):return o.id=='final_hint'))
 g.save_data.letters=g.save_data.riddle_letters.duplicate()
 for n in range(7):g.press_riddle_symbol('sun',Vector2.ZERO)
 assert(g.puzzle.size()==7 and g.puzzle.all(func(s):return s=='sun'));g.check_riddle_chest();assert(not g.save_data.finished);assert(g.puzzle.size()==7);print('PASS arbitrary input retained, wrong answer rejected only at chest')
 g.press_riddle_symbol('puzzle_reset',Vector2.ZERO);assert(g.puzzle.is_empty())
 for id in order:g.press_riddle_symbol(id,Vector2.ZERO)
 g.save_data.letters=[];g.check_riddle_chest();assert(not g.save_data.finished)
 g.save_data.letters=g.save_data.riddle_letters.duplicate();g.check_riddle_chest();assert(g.save_data.finished);print('PASS correct seven-symbol answer requires all seven clues')
 g.queue_free();await process_frame;quit()
