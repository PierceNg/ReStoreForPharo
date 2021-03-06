"
ReStore
©2019 John Aspinall
https://github.com/rko281/ReStoreForDolphin
https://github.com/rko281/ReStoreForPharo
"
Class {
	#name : #SSWReStoreSpeedTest,
	#superclass : #SSWReStorePersonTest,
	#category : #'SSW ReStore Tests'
}

{ #category : #public }
SSWReStoreSpeedTest >> sampleSet [

	^(1 to: self sampleSize) collect: 
		[ :e | 
		SimplePerson new 
			surname: 'Smith'; 
			firstName: 'John'; 
			emailAddress: 'john@something'; 
			yourself]
]

{ #category : #Running }
SSWReStoreSpeedTest >> sampleSize [

	^100
]

{ #category : #'unit tests' }
SSWReStoreSpeedTest >> test1Write [

	| people time |

	reStore destroyAllClasses.
	reStore synchronizeAllClasses.

	people := self sampleSet.

	Transcript 
		cr; 
		show: 'Writing '; print: self sampleSize; show: ' objects... ';
		show: (time := Time millisecondsToRun: [people storeIn: reStore]) displayString;
		show: ' ms'.

	self assert: ((reStore instancesOf: SimplePerson) size = self sampleSize).
	self assert: (time < (self sampleSize * 2)) "Fairly arbitrary but keeps an eye on things"
]

{ #category : #'unit tests' }
SSWReStoreSpeedTest >> test2Read [

	| people time |

	reStore destroyAllClasses.
	reStore synchronizeAllClasses.
	self sampleSet storeAllIn: reStore.

	reStore simulateReconnect.

	people := reStore instancesOf: SimplePerson.

	Transcript 
		cr; 
		show: 'Reading '; print: self sampleSize; show: ' objects... ';
		show:  (time := Time millisecondsToRun: [people := people asOrderedCollection]) displayString;
		show: ' ms'.

	self assert: (people size = self sampleSize).
	self assert: (time < (self sampleSize // 2)) "Fairly arbitrary but keeps an eye on things"
]

{ #category : #public }
SSWReStoreSpeedTest >> test3Update [

	| people time |

	reStore destroyAllClasses.
	reStore synchronizeAllClasses.
	self sampleSet storeAllIn: reStore.

	reStore simulateReconnect.

	people := (reStore instancesOf: SimplePerson) asOrderedCollection.
	people do: 
		[ :person || id |
		id := person _id.
		id odd 
			ifTrue: [person firstName: (person firstName, id displayString)] 
			ifFalse: [person surname: (person surname, id displayString)]].

	Transcript 
		cr; 
		show: 'Updating '; print: self sampleSize; show: ' objects... ';
		show:  (time := Time millisecondsToRun: [people storeAll]) displayString;
		show: ' ms'.

	reStore simulateReconnect.
	(reStore instancesOf: SimplePerson) asOrderedCollection do: 
		[ :person || id |
		id := person _id.
		id odd 
			ifTrue: [self assert: person firstName equals: ('John', id displayString)] 
			ifFalse: [self assert: person surname equals: ('Smith', id displayString)]].

	self assert: (time < (self sampleSize * 2)) "Fairly arbitrary but keeps an eye on things"
]

{ #category : #public }
SSWReStoreSpeedTest >> test4RefreshNoChange [

	| people time |

	reStore destroyAllClasses.
	reStore synchronizeAllClasses.
	self sampleSet storeAllIn: reStore.

	reStore simulateReconnect.

	people := (reStore instancesOf: SimplePerson) asOrderedCollection.

	Transcript 
		cr; 
		show: 'Refreshing (no change) '; print: self sampleSize; show: ' objects... ';
		show:  (time := Time millisecondsToRun: [people refreshAll]) displayString;
		show: ' ms'.

	self assert: (time < (self sampleSize * 2)) "Fairly arbitrary but keeps an eye on things"
]

{ #category : #public }
SSWReStoreSpeedTest >> test5RefreshWithChange [

	| people time |

	reStore destroyAllClasses.
	reStore synchronizeAllClasses.
	self sampleSet storeAllIn: reStore.

	reStore simulateReconnect.

	people := (reStore instancesOf: SimplePerson) asOrderedCollection.

	reStore connection evaluateAsTxn:
		[people do: 
			[ :person || id |
			id := person _id.
			id odd ifTrue: [reStore connection exec: ('update simple_person set first_name = ''changed'', version_ = version_ + 1 where id_ = <1p>' expandMacrosWith: id)]].
		true].

	Transcript 
		cr; 
		show: 'Refreshing (changed) '; print: self sampleSize; show: ' objects... ';
		show:  (time := Time millisecondsToRun: [people refreshAll]) displayString;
		show: ' ms'.

	people do: 
		[ :person || id |
		id := person _id.
		id odd
			ifTrue: [self assert: person firstName equals: 'changed'] 
			ifFalse: [self assert: person firstName equals: 'John']].

	self assert: (time < (self sampleSize * 3)) "Fairly arbitrary but keeps an eye on things"
]

{ #category : #public }
SSWReStoreSpeedTest >> test9Delete [

	| people time |

	reStore destroyAllClasses.
	reStore synchronizeAllClasses.
	self sampleSet storeAllIn: reStore.

	reStore simulateReconnect.

	people := (reStore instancesOf: SimplePerson) asOrderedCollection.
	
	Transcript 
		cr; 
		show: 'Deleting '; print: self sampleSize; show: ' objects... ';
		show:  (time := Time millisecondsToRun: [people unstoreAll]) displayString;
		show: ' ms'.

	self assert: (reStore instancesOf: SimplePerson) isEmpty.
	self assert: (time < (self sampleSize * 2)) "Fairly arbitrary but keeps an eye on things"
]
