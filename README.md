# Efficient-Learning-Free-Keyword-Spotting
Implementation of the method presented at "Efficient Learning-Free Keyword Spotting" (https://ieeexplore.ieee.org/abstract/document/8378004/)

A method for KWS, consisted of three steps:
1) Preprocessing (contrast and main-zone normalization)
2) Feature extraction (projections of Oriented Gradients - POG) over image zones
3) Matching sequences of descriptors with dynamic programming
 

* Implemented using Matlab 2015a! (possible compatibility problems for other versions)
* The matching algorithm is implemented in C (inner_valid_seq_multi.c) and was compiled via mex for Linux arch64. For different architecture re-compile the mathing code (`<addr>` mex inner_valid_seq_multi.c)
