"""Verify bundled expected RGB against the unchanged B scalar oracle."""
from pathlib import Path
import argparse,sys,json
import numpy as np
HERE=Path(__file__).resolve().parent
sys.path.insert(0,str(HERE/'reference'))
from oracle import solve_h,rectify,audit
p=argparse.ArgumentParser();p.add_argument('--size',choices=['reduced','fullhd','all'],default='reduced');a=p.parse_args()
for size in (['reduced','fullhd'] if a.size=='all' else [a.size]):
 folder=HERE/'fixtures'/size;m=json.loads((folder/'metadata.json').read_text())
 sw,sh=m['source'];ow,oh=m['storage'];total=0
 for record in m['frames']:
  i=record['variant'];packed=np.loadtxt(folder/f'source{i}.hex',dtype=np.uint32,converters=lambda x:int(x,16))
  image=np.stack(((packed>>16)&255,(packed>>8)&255,packed&255),axis=-1).astype(np.uint8).reshape(sh,sw,3)
  expected_words=np.loadtxt(folder/f'expected{i}.hex',dtype=np.uint32,converters=lambda x:int(x,16))
  expected=np.stack(((expected_words>>16)&255,(expected_words>>8)&255,expected_words&255),axis=-1).astype(np.uint8).reshape(oh,ow,3)
  h=solve_h(record['corners'],m['active_w'],oh,sw,sh)
  actual=rectify(image,h,m['active_w'],oh,ow,m['active_x'],'bilinear')
  np.testing.assert_array_equal(actual,expected)
  audit(image,expected,h,record['corners'],m['active_w'],oh,m['active_x'],'bilinear')
  total+=ow*oh
 print(f'VECTORS_PASS size={size} variants=3 pixels={total}')
