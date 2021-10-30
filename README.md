# IEEEAccess2021
# Investigation of SAEAs’ metamodel samples for computationally expensive optimization problems

> **Contributors:** Mônica A. C. Valadão<sup>1,4</sup>, André L. Maravilha<sup>2,4</sup>, Lucas S. Batista<sup>3,4</sup>   
> <sup>1</sup> *Science and Technology Institute - Universidade Federal dos Vales do Jequitinhonha e Mucuri ([url](https://www.ict.ufvjm.edu.br/))*   
> <sup>2</sup> *Dept. of Informatics, Management and Design - Centro Fed. de Edu. Tecnológica de Minas Gerais ([url](https://www.cefetmg.br/))*  
> <sup>3</sup> *Dept. Electrical Engineering - Universidade Federal de Minas Gerais ([url](http://www.dee.ufmg.br/))*  
> <sup>4</sup> *Operations Research and Complex Systems Lab. - Universidade Federal de Minas Gerais ([url](http://orcslab.ppgee.ufmg.br/))*


# About this repository

This repository contains the source code of the manuscript entitled "Investigation of SAEAs’ metamodel samples for computationally expensive optimization problems", written by Mônica A. C. Valadão, André L. Maravilha and Lucas S. Batista, submitted to the *IEEE Access* journal ([url](https://ieeeaccess.ieee.org/)).


# About this work 

Surrogate Model Assisted Evolutionary Algorithms (SAEAs) are strategies widely applied to deal with computationally expensive optimization problems. These methods employ metamodels to guide Evolutionary Algorithms to promising design regions where new evaluations on the true objective function must be performed. To do so, SAEAs are required to handle with the challenge of training a metamodel to improve its predictions. The reliability of a metamodel is strongly related to the samples used to train it. Despite this, several SAEAs are proposed without any concern about the sampling strategy for the construction of the metamodel.

The ideal situation is to obtain a sample which is not far from the solutions to predicted on the metamodel. In this sense, this paper performs an investigative study to compare five different strategies to define the metamodel sample in a proposed SAEA Framework (SAEA/F). The SAEA/F uses an  one-dimensional Ordinary Kriging metamodel, in which an Expected Improvement merit function is applied to define on which solutions to spend the budget of true function evaluation. In this investigation, each strategy is incorporated into the SAEA/F, which is used to solve a set of analytical functions of single-objective optimization problems.

Computational results suggest that two of five sampling strategies stand out as the best ones. The first strategy chooses those solutions with the lowest distance to the centroid of solutions from the population, while the second one selects the newest solutions evaluated on true function. Besides, the results highlight the potential of these approaches for solving expensive optimization problems since they speed-up the algorithm convergence to improved solutions.
