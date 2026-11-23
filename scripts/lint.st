| classes results dirty |
classes := Smalltalk globals allClasses select: [ :each |
  (each package name beginsWith: 'PuntObserve-') or: [ each = BaselineOfPuntObserve ] ].
classes ifEmpty: [ self error: 'No PuntObserve classes loaded' ].
results := OrderedCollection new.
dirty := false.
(classes sorted: [ :first :second | first name < second name ]) do: [ :each |
  | findings |
  findings := OrderedCollection new.
  (each methods , each class methods) do: [ :method |
    method critiques do: [ :critique |
      findings add: method methodClass name , ' >> #' , method selector , ': ' , critique rule name ] ].
  each critiques do: [ :critique | findings add: each name , ': ' , critique rule name ].
  findings ifEmpty: [ results add: each name , ': clean' ] ifNotEmpty: [ dirty := true. results addAll: findings ] ].
{ String cr join: results. dirty not }
