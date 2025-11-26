<table><table><tr><td><b>yaml description</b></td><td><b>scheme description</b></td><td><table><tr><td><pre><b>yaml e.g.</b></pre></td><td><pre><b>scheme e.g.</b></pre></td></tr></table></td></tr><tr><td>null</td><td>empty list</td><td><table><tr><td><pre>null</pre></td><td><pre>(list)</pre></td></tr><tr><td><pre>~</pre></td><td><pre>'()</pre></td></tr></table></td></tr><tr><td>document</td><td>list</td><td><table><tr><td><pre>--- 2
---
...</pre></td><td><pre>(list 2 (list))</pre></td></tr></table></td></tr><tr><td>mapping</td><td>A list contain only 1 "association list"</td><td><table><tr><td><pre>{key: value}</pre></td><td><pre>'((("key" . "value")))</pre></td></tr></table></td></tr><tr><td>list</td><td>vector</td><td><table><tr><td><pre>#
- 1
- 2
- 3
- 4
- []</pre></td><td><pre>(vector
1
2
3
4
(vector))</pre></td></tr></table></td></tr><tr><td>boolean</td><td>boolean</td><td><table><tr><td><pre>true</pre></td><td><pre>#t</pre></td></tr><tr><td><pre>false</pre></td><td><pre>#f</pre></td></tr></table></td></tr><tr><td>number</td><td>exact or inexact</td><td><table><tr><td><pre>1</pre></td><td><pre>1</pre></td></tr><tr><td><pre>0.5</pre></td><td><pre>0.5</pre></td></tr><tr><td><pre>0o10</pre></td><td><pre>8</pre></td></tr><tr><td><pre>0x10</pre></td><td><pre>16</pre></td></tr><tr><td><pre>10e1</pre></td><td><pre>100.0</pre></td></tr><tr><td><pre>3E2</pre></td><td><pre>300.0</pre></td></tr></table></td></tr><tr><td>not a number</td><td>not a number</td><td><table><tr><td><pre>.nan</pre></td><td><pre>+nan.0</pre></td></tr></table></td></tr><tr><td>infinity</td><td>infinity</td><td><table><tr><td><pre>+.inf</pre></td><td><pre>+inf.0</pre></td></tr><tr><td><pre>-.inf</pre></td><td><pre>-inf.0</pre></td></tr></table></td></tr></table>