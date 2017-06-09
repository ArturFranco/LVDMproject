import random
import math

def vdm(dfProb,X,Y):

	

def lvdm(T,q,X,Y):

	#search in the tree and return a vector of neighborhood instances
	#the function must verify if l < q
	vet = searchTree(T,q,Y)

	dfProb = buildProbTable(vet)

	distance = vdm(dfProb,X,Y)

	return distance

