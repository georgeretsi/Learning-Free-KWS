# Efficient-Learning-Free-Keyword-Spotting
Implementation of the method presented at "Efficient Learning-Free Keyword Spotting" (https://ieeexplore.ieee.org/abstract/document/8378004/)

A method for KWS, consisted of three steps:
1) Preprocessing (contrast and main-zone normalization)
2) Feature extraction (projections of Oriented Gradients - POG) over image zones
3) Matching sequences of descriptors with dynamic programming
 
**Implementation Highlights:**
* Implemented using Matlab 2015a (possible compatibility issues for other versions).
* Feature extraction is using multiple threads (Matlab's parfor). 
* The matching algorithm is implemented in C (inner_valid_seq_multi.c) and was compiled via mex for Linux arch64. For different architecture re-compile the mathing algorithm:
<code>mex inner_valid_seq_multi.c<\code>
* The dataloaders for both the datasets of ICFHR 2014 Keyword Spotting Competition are provided (Bentham14 & Modern14).
* 3 methods are supported:
	1. 'Global' : simple holistic POG descriptor
	2. 'GlobalZoned' : use POG descriptor over zones across the word image
	3. 'Sequential': the proposed method using the sequential matching. The multi instance case, decribed at the manuscript, is also supported.
