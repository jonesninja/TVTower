
Type TPlayerProgrammePlan
	field ProgrammeBlocks:TList = CreateList()
	Field Contracts:TObjectList		= TObjectList.Create(1000)
	Field NewsBlocks:TList		= CreateList()
	Global List:TObjectList			= TObjectList.Create(1000)

	field AdditionallyDraggedProgrammeBlocks:int = 0

	Field parent:TPlayer

	Method ClearLists()
		List.Clear()
		ProgrammeBlocks.Clear()
		Contracts.Clear()
		NewsBlocks.Clear()
	End Method

	Function Create:TPlayerProgrammePlan(parent:TPlayer)
		Local obj:TPlayerProgrammePlan = New TPlayerProgrammePlan
		TPlayerProgrammePlan.List.AddLast(obj)
		obj.parent = parent
		Return obj
	End Function

	Method AddProgrammeBlock:TLink(block:TProgrammeBlock)
		return self.ProgrammeBlocks.addLast(block)
	End Method

	Method GetProgrammeBlock:TProgrammeBlock(id:Int)
		For Local obj:TProgrammeBlock = EachIn self.ProgrammeBlocks
			If obj.id = id Then Return obj
		Next
		return null
	EndMethod

	Method GetActualProgrammeBlock:TProgrammeBlock(time:Int = -1, day:Int = - 1)
		If time = -1 Then time = Game.GetActualHour()
		If day  = -1 Then day  = Game.day
		local planHour:int = day*24 + time

		for local block:TProgrammeBlock = eachin self.ProgrammeBlocks
			If (block.sendHour + block.Programme.blocks - 1 >= planHour And block.sendHour <= planHour) Then Return block
		Next
		Return Null
	End Method

	'returns a number based on day to send and hour from position
	'121 means 5 days and 1 hours -> 01:00 on day 5
	Function GetPlanHour:int(dayHour:int, dayToPlan:int=null)
		if dayToPlan = null then dayToPlan = game.daytoplan
		return dayToPlan*24 + dayHour
	End Function

    Method DrawAllProgrammeBlocks()
		if self.AdditionallyDraggedProgrammeBlocks > 0
			For local ProgBlock:TProgrammeBlock = EachIn self.ProgrammeBlocks
				If self.parent.playerID = Game.playerID And ProgBlock.dragged=1 then ProgBlock.DrawShades()
			Next
		Endif
		For Local ProgrammeBlock:TProgrammeBlock = EachIn self.ProgrammeBlocks
			ProgrammeBlock.Draw()
		Next
    End Method

	Method UpdateAllProgrammeBlocks()
		Local gfxListenabled:Byte = (PPprogrammeList.enabled <> 0 Or PPcontractList.enabled <> 0)
		'assume all are dropped
		self.AdditionallyDraggedProgrammeBlocks = 0

		self.ProgrammeBlocks.sort()
		Local clickrecognized :Byte = 0

		For Local block:TProgrammeBlock = EachIn self.ProgrammeBlocks
			If gfxListenabled = 0 And MOUSEMANAGER.IsHit(2) And block.dragged = 1
				block.DeleteBlock() 'removes block from Programmeplan
				MOUSEMANAGER.resetKey(2)
			EndIf

			If gfxListenabled=0 And Not Clickrecognized And MOUSEMANAGER.IsHit(1)
				If not block.dragged
					If block.dragable And block.State = 0 And functions.DoMeet(block.sendhour, block.sendhour+block.programme.blocks, Game.daytoplan*24,Game.daytoplan*24+24)
						For Local i:Int = 1 To block.programme.blocks
							local pos:TPosition = block.GetBlockSlotXY(i, block.pos)
							if functions.MouseIn(pos.x, pos.y, block.width, 30)
								block.Drag()
								exit
							EndIf
						Next
					EndIf
				Else 'drop dragged block
					Local DoNotDrag:Int = 0
					If gfxListenabled = 0 And MOUSEMANAGER.IsHit(1) And block.State = 0
						For Local DragAndDrop:TDragAndDrop = EachIn block.DragAndDropList  					'loop through DnDs
							If DragAndDrop.Drop(MouseX(),MouseY(), "programmeblock") = 1					'mouse within dnd-rect
								For Local Otherblock:TProgrammeBlock = EachIn self.ProgrammeBlocks   		'loop through other pblocks
									'is there a block positioned at the desired place?

									'is otherblock not the same as our actual block? - on the same day
									If Otherblock <> block
										Local dndHour:Int = game.daytoplan*24 + (DragAndDrop.pos.x = 394)*12 + (DragAndDrop.pos.y - 17) / 30		'timeset calc.

										'loop through aimed time + duration in scheduler
										if functions.DoMeet(dndHour, dndHour+block.programme.blocks-1,  otherblock.sendHour, otherBlock.sendHour + otherBlock.programme.blocks-1)
											clickrecognized = 1
											If not Otherblock.DraggingAllowed()
												DoNotDrag = 1
												block.Drag()
												Otherblock.Drop()
												'print "would swap "+block.programme.title+" with "+otherblock.programme.title + " but not allowed"
												exit
											EndIf
										EndIf
									endif
								Next
								If DoNotDrag <> 1
									block.Pos.SetXY(DragAndDrop.pos.x, DragAndDrop.pos.y)
									block.StartPos.SetPos(block.Pos)
									clickrecognized = 1

									block.sendhour = self.getPlanHour(block.GetHourOfBlock(1, block.pos), game.daytoplan)
									block.Drop()
									Exit 'exit loop-each-dragndrop, we've already found the right position
								EndIf
							EndIf
						Next
						If block.IsAtStartPos() And DoNotDrag = 0 And (Game.day < Game.daytoplan Or (Game.day = Game.daytoplan And Game.GetActualHour() < block.GetHourOfBlock(1,block.StartPos)))
							block.Drop()
							block.Pos.SetPos(block.StartPos)
						EndIf
					EndIf
				EndIf
			EndIf

			If block.dragged = 1
				self.AdditionallyDraggedProgrammeBlocks :+1
				local displace:int = self.AdditionallyDraggedProgrammeBlocks *5
				block.Pos.SetXY(MouseX() - block.width/2 - displace, MouseY() - block.height/2 - displace)
			EndIf
		Next
    End Method

	Method GetNewsBlock:TNewsBlock(id:Int)
		For Local obj:TNewsBlock = EachIn self.NewsBlocks
			If obj.id = id Then Return obj
		Next
		return null
	EndMethod


	Method DrawAllNewsBlocks()
		For Local NewsBlock:TNewsBlock = EachIn self.NewsBlocks
			If self.parent.playerID = Game.playerID
				If (newsblock.dragged=1 Or (newsblock.pos.y > 0)) And (Newsblock.publishtime + Newsblock.publishdelay <= Game.timeSinceBegin) then NewsBlock.Draw()
			EndIf
		Next
    End Method

    Method UpdateAllNewsBlocks()
		Local havetosort:Byte = 0
		Local dontpay:Int = 0
		Local number:Int = 0
		If TNewsBlock.LeftListPositionMax >=4
			If TNewsBlock.LeftListPosition+4 > TNewsBlock.LeftListPositionMax Then TNewsBlock.LeftListPosition = TNewsBlock.LeftListPositionMax-4
		Else
			TNewsBlock.LeftListPosition = 0
		EndIf

		self.NewsBlocks.sort(true, TNewsBlock.sort)

		For Local NewsBlock:TNewsBlock = EachIn self.NewsBlocks
			If NewsBlock.owner = Game.playerID
				If newsblock.GetSlotOfBlock() < 0 And (Newsblock.publishtime + Newsblock.publishdelay <= Game.timeSinceBegin)
					number :+ 1
					If number >= TNewsBlock.LeftListPosition And number =< TNewsBlock.LeftListPosition+4
						NewsBlock.Pos.SetXY(35, 22+88*(number-TNewsBlock.LeftListPosition   -1))
					Else
						NewsBlock.pos.SetXY(0, -100)
					EndIf
					NewsBlock.StartPos.SetPos(NewsBlock.Pos)
				EndIf
				If newsblock.GetSlotOfBlock() > 0 Then dontpay = 1
				If NewsBlock.dragged = 1
					NewsBlock.sendslot = -1
					If MOUSEMANAGER.IsHit(2)
						TDragAndDrop.SetDragAndDropTargetState(0,newsBlock.DragAndDropList, newsBlock.StartPos)
						If game.networkgame Then If network.IsConnected Then Network.SendPlanNewsChange(game.playerID, newsblock, 2)
						Player[Game.playerID].ProgrammePlan.RemoveNewsBlock(NewsBlock)
						havetosort = 1
						MOUSEMANAGER.resetKey(2)
					EndIf
				endif
				If MOUSEMANAGER.IsHit(1)
					If NewsBlock.dragged = 0 And NewsBlock.dragable = 1 And NewsBlock.State = 0
						If functions.IsIn(MouseX(), MouseY(), NewsBlock.pos.x, NewsBlock.pos.y, NewsBlock.width, NewsBlock.height)
							NewsBlock.dragged = 1
							If game.networkgame Then If network.IsConnected Then Network.SendPlanNewsChange(game.playerID, newsblock, 1)
						EndIf
					Else
						Local DoNotDrag:Int = 0
						if NewsBlock.State = 0
							NewsBlock.dragged = 0
							For Local DragAndDrop:TDragAndDrop = EachIn TNewsBlock.DragAndDropList
								If DragAndDrop.Drop(MouseX(),MouseY()) = 1
									For Local OtherNewsBlock:TNewsBlock = EachIn self.NewsBlocks
										If OtherNewsBlock.owner = Game.playerID
											'is there a NewsBlock positioned at the desired place?
											If MOUSEMANAGER.IsHit(1) And OtherNewsBlock.dragable = 1 And OtherNewsBlock.pos.isSame(DragAndDrop.pos)
												If OtherNewsBlock.State = 0
													OtherNewsBlock.dragged = 1
													If game.networkgame Then If network.IsConnected Then Network.SendPlanNewsChange(game.playerID, otherNewsBlock, 1)
													exit
												Else
													DoNotDrag = 1
												EndIf
											EndIf
										EndIf
									Next
									If DoNotDrag <> 1
										NewsBlock.Pos.SetPos(DragAndDrop.pos)
										TDragAndDrop.SetDragAndDropTargetState(0,newsBlock.DragAndDropList, newsBlock.StartPos)
										TDragAndDrop.SetDragAndDropTargetState(1,newsBlock.DragAndDropList, newsBlock.pos)
										NewsBlock.StartPos.SetPos(NewsBlock.Pos)
										Exit 'exit loop-each-dragndrop, we've already found the right position
									EndIf
								EndIf
							Next
							If NewsBlock.IsAtStartPos()
								If Not newsblock.paid And newsblock.pos.x > 400
									NewsBlock.Pay()
									newsblock.paid=True
								EndIf
								NewsBlock.dragged    = 0
								NewsBlock.Pos.SetPos(NewsBlock.StartPos)
								NewsBlock.sendslot   = Newsblock.GetSlotOfBlock()
								If NewsBlock.sendslot >0 And NewsBlock.sendslot < 4
									If game.networkgame Then If network.IsConnected Then Network.SendPlanNewsChange(game.playerID, newsblock, 0)
								EndIf
								SortList self.NewsBlocks
							EndIf
						EndIf
					EndIf
				EndIf
				If NewsBlock.dragged = 1
					TNewsBlock.AdditionallyDragged = TNewsBlock.AdditionallyDragged +1
					NewsBlock.Pos.SetXY(MouseX() - NewsBlock.width /2 - TNewsBlock.AdditionallyDragged *5, MouseY() - NewsBlock.height /2 - TNewsBlock.AdditionallyDragged *5)
				EndIf
				If NewsBlock.dragged = 0
					NewsBlock.Pos.SetPos(NewsBlock.StartPos)
				EndIf
			EndIf
		Next
		TNewsBlock.LeftListPositionMax = number
		TNewsBlock.AdditionallyDragged = 0
    End Method


	Method ProgrammePlaceable:Int(Programme:TProgramme, time:Int = -1, day:Int = -1)
		If Programme = Null Then Return 0
		If time = -1 Then time = Game.GetActualHour()
		If day  = -1 Then day  = Game.day

		If GetActualProgramme(time, day) = Null
			If time + Programme.blocks - 1 > 23 Then time:-24;day:+1 'sendung geht bis nach 0 Uhr
			If GetActualProgramme(time + Programme.blocks - 1, day) = Null then Return 1
		EndIf
		Return 0
	End Method

	Method ContractPlaceable:Int(Contract:TContract, time:Int = -1, day:Int = -1)
		If Contract = Null Then Return 0
		If time = -1 Then time = Game.GetActualHour()
		If day  = -1 Then day  = Game.day
		If GetActualContract(time, day) = Null then Return 1
		Return 0
	End Method

	Method GetActualProgramme:TProgramme(time:Int = -1, day:Int = - 1)
		If time = -1 Then time = Game.GetActualHour()
		If day  = -1 Then day  = Game.day
		local planHour:int = day*24+time

		for local block:TProgrammeBlock = eachin self.ProgrammeBlocks
			If (block.sendHour + block.Programme.blocks - 1 >= planHour) Then Return block.programme
		Next
		Return Null
	End Method

	Method GetActualContract:TContract(time:Int = -1, day:Int = - 1)
		If time = -1 Then time = Game.GetActualHour()
		If day  = -1 Then day  = Game.day

		Local contract:TContract=Null
		For Local i:Int = 0 To self.Contracts.Count()-1
			contract = TContract(self.Contracts.items[i] )
			If (contract.sendtime>= time And contract.sendtime <=time) And contract.senddate = day Then Return contract
		Next
		Return Null
	End Method

	Method GetActualAdBlock:TAdBlock(playerID:Int, time:Int = -1, day:Int = - 1)
		If time = -1 Then time = Game.GetActualHour()
		If day  = -1 Then day  = Game.day

		For Local adblock:TAdBlock= EachIn TAdBlock.List
			If adblock.owner = playerID
				If (adblock.contract.sendtime>= time And adblock.contract.sendtime <=time) And..
					adblock.contract.senddate = day Then Return adblock
			EndIf
		Next
		Return Null
	End Method

	Method GetActualNewsBlock:TNewsBlock(position:Int)
		For Local newsBlock:TNewsBlock = eachin self.NewsBlocks
			If newsBlock.sendslot = position Then Return newsBlock
		Next
	End Method

	Method RefreshAdPlan(day:Int)
		Local contract:TContract = Null
		For Local i:Int = 0 To self.Contracts.count()-1
			contract = TContract( self.Contracts.items[i] )
			If contract.senddate = day Then self.RemoveContract(contract)
		Next
		For Local Adblock:TAdBlock= EachIn TAdBlock.List
			If adblock.contract.owner = self.parent.playerID
				Print "REFRESH AD:ADDED "+adblock.contract.title;
				self.AddContract(adblock.contract)
			EndIf
		Next
	End Method


	Method RemoveProgramme(_Programme:TProgramme)
		'remove all blocks using that programme
		For local block:TProgrammeBlock = eachin self.ProgrammeBlocks
			if block.programme = _Programme AND block.sendhour + block.programme.blocks > game.day*24+game.getActualHour() then self.ProgrammeBlocks.remove(block)
		Next

		'remove programme from player programme list
		Player[self.parent.playerID].ProgrammeCollection.RemoveProgramme( _Programme )
	End Method

	Method AddContract(_Contract:TContract)
		Local contract:TContract = New TContract
		contract			= CloneContract(_Contract)
		contract.owner		= self.parent.playerID
		contract.senddate	= Game.daytoplan
		self.Contracts.AddLast(contract)
		GetPreviousContractCount(contract)
	End Method

	Method AddNewsBlock(block:TNewsBlock)
		self.NewsBlocks.AddLast(block)
	End Method

	Method RemoveNewsBlock(block:TNewsBlock)
		self.NewsBlocks.remove(block)
	End Method

	'clones a TProgramme - a normal prog = otherprog
	'just creates a reference to this object, but we want
	'a real copy (to be able to send repeatitions of movies
	Function CloneContract:TContract(_contract:TContract)
		If _contract <> Null
			Local typ:TTypeId = TTypeId.ForObject(_contract)
			Local clone:TContract = New TContract
			For Local t:TField = EachIn typ.EnumFields()
				t.Set(clone, t.Get(_contract))
			Next
			TContract(clone).clone = 1
			clone.botched = 0
			clone.finished = 0
			clone.owner = 0
			Return clone
		EndIf
	End Function

	Method RemoveContract(_contract:TContract)
		Local contract:TContract = Null
		For Local i:Int = 0 To self.Contracts.Count()-1
			contract = TContract(self.Contracts.Items[i] )
			If contract <> Null AND contract.title = _contract.title and contract.senddate = _contract.senddate and contract.sendtime = _contract.sendtime
				self.Contracts.RemoveByIndex(i)
			EndIf
		Next
	End Method

	Method GetPreviousContractCount:Int(_contract:TContract)
		Local count:Int = 1
		If Not self.Contracts Then self.Contracts = TObjectList.Create(1000)
		Local contract:TContract = Null
		For Local i:Int = 0 To self.Contracts.Count()-1
			contract = TContract(self.Contracts.Items[i] )
			If contract.title = _contract.title And contract.botched <> 1
				contract.spotnumber = count
				count :+ 1
			EndIf
		Next
		Return count
	End Method

	Method RenewContractCount:Int(_contract:TContract)
		Local count:Int = 1
		Local contract:TContract = Null
		For Local i:Int = 0 To self.Contracts.Count()-1
			contract = TContract(self.Contracts.items[i] )
			If contract.title = _contract.title
				If contract.botched <> 1
					contract.spotnumber = count
					count :+1
				else
					contract.spotnumber = 0
				EndIf
			EndIf
		Next
	End Method
End Type


GLOBAL TYPE_MOVIE:int = 1
GLOBAL TYPE_SERIE:int = 2
GLOBAL TYPE_EPISODE:int = 4
GLOBAL TYPE_CONTRACT:int = 8
GLOBAL TYPE_AD:int = 16
GLOBAL TYPE_NEWS:int = 32

'holds all Programmes a player possesses
Type TPlayerProgrammeCollection' Extends TProgramme
	Field List:TList			= CreateList()
	Field MovieList:TList		= CreateList()
	Field SeriesList:TList		= CreateList()
	Field ContractList:TList	= CreateList()

	Method ClearLists()
		List.Clear()
		MovieList.Clear()
		SeriesList.Clear()
		ContractList.Clear()
	End Method

  'removes Contract from Collection (Advertising-Menu in Programmeplanner)
  Method RemoveOriginalContract(_contract:TContract)
    If _contract <> Null
	  For Local contract:TContract = EachIn ContractList
	    Print contract.title + " = " +_contract.title + " and contract.clone = "+contract.clone
        If contract.title = _contract.title And contract.clone = 0
	      'Print "removing contract:"+contract.title
     	  ContractList.Remove(contract)
     	  Exit
        End If
      Next
	EndIf
  End Method

  Method RemoveProgramme:Int(programme:TProgramme, owner:Int=0)
    If programme <> Null
  	  'Print "removed programme:"+programme.title
	  List.remove(programme)
	  MovieList.remove(programme)
	EndIf
  End Method

  Method AddMovie:Int(movie:TProgramme, owner:Int=0)
    If movie <> Null
      movie.used = owner
      MovieList.AddLast(movie)
      List.AddLast(movie)
      'Print "added to collection: "+movie.title + " with Blocks:"+movie.blocks
	EndIf
  End Method

  Method AddContract:Int(contract:TContract, owner:Int=0)
    If contract <> Null
      contract.owner = owner
      'Print "Contract: set to owner "+owner
      contract.calculatedMinAudience = contract.GetMinAudienceNumber(contract.minaudience)
      'DebugLog contract.calculatedMinAudience + " ("+contract.GetMinAudiencePercentage(contract.minaudience)+"%)"
      Self.ContractList.AddLast(contract)
  	  TContractBlocks.Create(contract, 1,owner)
	EndIf
  End Method

  Method AddProgramme:Int(programme:TProgramme, owner:Int = 0)
    If programme <> Null
      programme.used = owner
      If programme.isMovie Then MovieList.AddLast(programme) Else SeriesList.AddLast(programme)
      List.AddLast(programme)
	EndIf
  End Method

  Method AddSerie:Int(serie:TProgramme, owner:Int=0)
    If serie <> Null
      serie.used = owner
      SeriesList.AddLast(serie)
      List.AddLast(serie)
	EndIf
  End Method

  'GetLocalRandom... differs from GetRandom... for using it's personal programmelist
  'instead of the global one
  'returns a movie out of the players programmebouquet

	Method GetLocalRandomProgramme:TProgramme(serie:int = 0)
		if serie then return self.GetLocalRandomSerie()
		return self.GetLocalRandomMovie()
	End Method

	Method GetLocalRandomMovie:TProgramme()
		return TProgramme(MovieList.ValueAtIndex(Rnd(0, CountList(MovieList)-1)))
	End Method

	Method GetLocalRandomSerie:TProgramme()
		return TProgramme(SeriesList.ValueAtIndex(Rnd(0, CountList(SeriesList)-1)))
	End Method

	Method GetLocalRandomContract:TContract()
		return TContract(ContractList.ValueAtIndex(Rnd(0, CountList(ContractList)-1)))
	End Method

  Method GetProgramme:TProgramme(number:Int)
    For Local obj:TProgramme = EachIn Self.List
	  If Obj.id = number Then Return obj
    Next
    Return Null
  End Method

  Method GetContract:TContract(number:Int)
    For Local contract:TContract=EachIn Self.ContractList
	  If contract.id = number Then Return contract
    Next
    'Print "getcontract: contract not found"
    Return Null
  End Method

  Method GetMovieFromCollection:TProgramme(id:Int)
   For Local movie:TProgramme=EachIn MovieList
	 If movie.id = id Then Return movie
   Next
   Return Null
 End Method

  Method GetSeriesFromCollection:TProgramme(id:Int)
   For Local movie:TProgramme=EachIn SeriesList
	 If movie.id = id Then Return movie
   Next
   Return Null
 End Method

End Type


Type TProgrammeElement
	Field title:string
	Field description:string
	Field id:int = 0
	Field programmeType:int = 0
	global LastID:int = 0

	Method BaseInit(title:string, description:string, programmeType:int = 0)
		self.title = title
		self.description = description
		self.programmeType = programmeType
		self.id = self.LastID

		self.LastID :+1
	End Method
End Type

'ad-contracts
Type TContract extends TProgrammeElement
  Field daystofinish:Int
  Field spotcount:Int
  Field spotssent:Int
  Field spotnumber:Int = -1
  Field botched:Int =0
  Field senddate:Int = -1
  Field sendtime:Int = -1
  Field targetgroup:Int
  Field minaudience:Int
  Field profit:Int
  Field finished:Int =0
  Field clone:Int = 0 'is it a clone (used for adblocks) or the original one (contract-gfxlist)
  Field penalty:Int
  Field owner:Int = 0
  Field daysigned:Int 'day the contract has been taken from the advertiser-room
  Field calculatedProfit:Int =0
  Field calculatedPenalty:Int =0
  Field calculatedMinAudience:Int =0

  Global List:TList = CreateList() {saveload = "special"}
  Global MinAudienceMultiplicator:Double = 1000000 {saveload = "special"}

	Function Load:TContract(pnode:xmlNode)
		Local Contract:TContract = New TContract
		Local NODE:xmlNode = pnode.FirstChild()
		While NODE <> Null
			Local nodevalue:String = ""
			If NODE.Name = Upper("MINAUDIENCEMULTIPLICATOR")
				TContract.MinAudienceMultiplicator = Double(node.Attribute("var").Value)
			EndIf
			If NODE.Name = Upper("CONTRACTS")
				If node.HasAttribute("var", False) Then nodevalue = node.Attribute("var").value
				Local typ:TTypeId = TTypeId.ForObject(StationMap)
				For Local t:TField = EachIn typ.EnumFields()
					If t.MetaData("saveload") <> "special" And Upper(t.name()) = NODE.name
						t.Set(Contract, nodevalue)
					EndIf
				Next
				If contract.owner > 0 And contract.owner <= 4
				    If contract.clone > 0 Then Player[contract.owner].ProgrammePlan.AddContract(contract)
				    If contract.clone = 0 Then Player[contract.owner].ProgrammeCollection.AddContract(contract)
				EndIf
				If contract.clone = 0 Then TContract.List.AddLast(contract)
			EndIf
			NODE = NODE.nextSibling()
		Wend
		Return contract
	End Function

	Function LoadAll()
		PrintDebug("TContract.LoadAll()", "Lade Werbeverträge", DEBUG_SAVELOAD)
		TContract.List.Clear()
		Local Children:TList = LoadSaveFile.NODE.ChildList
		For Local node:xmlNode = EachIn Children
			If NODE.name = "ALLCONTRACTS"
			      TContract.Load(NODE)
			End If
		Next
	End Function

	Function SaveAll()
		LoadSaveFile.xmlBeginNode("ALLCONTRACTS")
			LoadSaveFile.xmlWrite("MINAUDIENCEMULTIPLICATOR", TContract.MinAudienceMultiplicator)
   			For Local Contract:TContract = EachIn TContract.List
     			Contract.Save()
   			Next
   		LoadSaveFile.xmlCloseNode()
	End Function

	Method Save()
		LoadSaveFile.xmlBeginNode("CONTRACT")
 			Local typ:TTypeId = TTypeId.ForObject(Self)
			For Local t:TField = EachIn typ.EnumFields()
				If t.MetaData("saveload") <> "special" Then LoadSaveFile.xmlWrite(Upper(t.name()), String(t.Get(Self)))
			Next
		LoadSaveFile.xmlCloseNode()
	End Method

	Function Create:TContract(title$, description$, daystofinish:Int, spotcount:Int, targetgroup:Int, minaudience:Int, profit:Int, penalty:Int, id:Int=0, owner:Int = 0)
		Local obj:TContract =New TContract
		obj.BaseInit(title, description, TYPE_CONTRACT)
		obj.daystofinish	= daystofinish
		obj.spotcount		= spotcount
		obj.spotssent		= 0
		obj.owner			= owner
		obj.spotnumber		=  1
		obj.targetgroup		= targetgroup
		obj.minaudience		= minaudience
		obj.profit			= profit
		obj.penalty     	= penalty
		obj.daysigned   	= -1

		TContract.List.AddLast(obj)
		SortList(TContract.List)
		Return obj
	End Function

	Function CalculateMinAudienceMultiplicator()
		Local maxaudience:Int = 0
		For Local MyPlayer:TPlayer = EachIn TPlayer.List
			If MyPlayer.maxaudience > maxaudience Then maxaudience = MyPlayer.maxaudience
		Next
		If maxaudience <=  50000 Then MinAudienceMultiplicator =   20000
		If maxaudience >   50000 Then MinAudienceMultiplicator =   50000
		If maxaudience >  100000 Then MinAudienceMultiplicator =  100000
		If maxaudience >  250000 Then MinAudienceMultiplicator =  250000
		If maxaudience >  500000 Then MinAudienceMultiplicator =  500000
		If maxaudience > 1000000 Then MinAudienceMultiplicator = 1000000
		If maxaudience > 5000000 Then MinAudienceMultiplicator = 5000000
		If maxaudience >10000000 Then MinAudienceMultiplicator =10000000
	End Function

   'up to now only for creation of playerbouquet (not for listing in advertiserroom)
	Function GetRandomContract:TContract()
		CalculateMinAudienceMultiplicator()
		Local contract:TContract = Null
		Repeat contract = TContract(List.ValueAtIndex(Rnd(0, CountList(List) - 1)))
		Until contract.daysigned = -1 And contract.owner = 0
		contract.daysigned = Game.day
		contract.calculatedMinAudience	= contract.CalculateMinAudience()
		contract.calculatedProfit		= contract.CalculatePrice(contract.profit)
		contract.calculatedPenalty		= contract.CalculatePrice(contract.penalty)
		Return contract
	End Function

	Function GetMinAudiencePercentage:Float(dbvalue:Int)
		select dbvalue
			case   0	Return 0
			case  25	Return 0.01
			case  50	Return 0.025
			case  75	Return 0.05
			case 100	Return 0.075
			case 125	Return 0.15
			case 150	Return 0.3
			case 175	Return 0.5
			case 200	Return 0.75
			case 225	Return 0.9
			default		Return 0
		endSelect
	End Function

	'multiplies basevalues of prices, values are from 0 to 255 for 1 spot... per 1000 people in audience
	'if targetgroup is set, the price is doubled
	Method CalculatePrice:Float(baseprice:Int=0)
		Local price:Float = 0
		Local audiencepercentage:Float = TContract.GetMinAudiencePercentage(minaudience)
		If audiencepercentage <= 0.05 Then audiencepercentage = 0.05
		price = baseprice * 1000 *audiencepercentage* spotcount
		Return price
	End Method

	'multiplies basevalues of prices, values are from 0 to 255 for 1 spot... per 1000 people in audience
	'if targetgroup is set, the price is doubled
	Method CalculateMinAudience:Float()
		Return TContract.MinAudienceMultiplicator * TContract.GetMinAudiencePercentage(minaudience)
	End Method

	Method GetMinAudienceNumber:Float(dbvalue:Int)
		If calculatedMinAudience = 0 Then calculatedMinAudience = CalculateMinAudience()
		Return calculatedMinAudience
	End Method

	Function GetTargetgroupName:String(group:Int)
		if group >= 1 and group <=9
			Return GetLocale("AD_GENRE_"+group)
		endif
		Return GetLocale("AD_GENRE_NONE")
	End Function

	Method getDaysToFinish:Int()
		Return (daystofinish-(Game.day - daysigned))
	End Method

	Method ShowSheet:Int(x:Int,y:Int, plannerday:Int = -1)
		Local calcminaudience:Int = GetMinAudienceNumber(minaudience)
		gfx_datasheets_contract.render(x,y)
		'DrawImage gfx_datasheets_contract,x,y
		local font:TBitmapFont = FontManager.basefont
		font.drawBlock(title 	       				, x+10 , y+11 , 270, 70,0, 0,0,0, 0,1)
		font.drawBlock(description     		 		, x+10 , y+33 , 270, 70)
		font.drawBlock(getLocale("AD_PROFIT")+": "	, x+10 , y+94 , 130, 16)
		font.drawBlock(functions.convertValue(String(calculatedProfit), 2, 0) , x+10 , y+94 , 130, 16,2)
		font.drawBlock(getLocale("AD_TOSEND")+": "    , x+150, y+94 , 127, 16)
		font.drawBlock(spotcount+"/"+spotcount , x+150, y+91 , 127, 19,2)
		font.drawBlock(getLocale("AD_PENALTY")+": "       , x+10 , y+117, 130, 16)
		font.drawBlock(functions.convertValue(String(calculatedPenalty), 2, 0), x+10 , y+117, 130, 16,2)
		font.drawBlock(getLocale("AD_MIN_AUDIENCE")+": "    , x+150, y+117, 127, 16)
		font.drawBlock(functions.convertValue(String(calcminaudience), 2, 0), x+150, y+117, 127, 16,2)
		font.drawBlock(getLocale("AD_TARGETGROUP")+": "+GetTargetgroupName(targetgroup)   , x+10 , y+140 , 270, 16)
		If getDaysToFinish() = 0
			font.drawBlock(getLocale("AD_TIME")+": "+getLocale("AD_TILL_TODAY") , x+86 , y+163 , 126, 16)
		Else If getDaysToFinish() = 1
			font.drawBlock(getLocale("AD_TIME")+": "+getLocale("AD_TILL_TOMORROW") , x+86 , y+163 , 126, 16)
		Else
			font.drawBlock(getLocale("AD_TIME")+": "+Replace(getLocale("AD_STILL_X_DAYS"),"%1", (daystofinish-(Game.day - daysigned))), x+86 , y+163 , 122, 16)
		EndIf
	End Method

	Function GetContract:TContract(number:Int)
		For Local contract:TContract = EachIn List
			If contract.id = number then Return contract
		Next
		Return Null
	End Function
End Type

Type TProgramme extends TProgrammeElement 'parent of movies, series and so on
	Field clone:Int = 0
	Field actors:String
	Field director:String
	Field country:String
	Field year:Int
	Field livehour:Int
	Field Outcome:Float
	Field review:Float
	Field speed:Float
	Field relPrice:Int
	Field Genre:Int
	Field episodecount:Int	 	= 0
	Field blocks:Int
	Field fsk18:int
	Field isMovie:Int			= 1
	Field episodeNumber:Int		= 0
	Field topicality:Int		= -1 				'how "attractive" a movie is (the more shown, the less this value)
	Field maxtopicality:Int 	= 255
	Field parent:TProgramme		= null
	Field episodeList:TList		= CreateList()  ' TObjectList = TObjectList.Create(100) {saveload = "nosave"}
	Field used:Int = 0

 Global ProgList:TList			= CreateList()   {saveload = "nosave"}
 Global ProgMovieList:TList		= CreateList() {saveload = "nosave"}
 Global ProgSeriesList:TList	= CreateList() {saveload = "nosave"}


	Function Create:TProgramme(title:String, description:String, actors:String, director:String, country:String, year:Int, livehour:Int, Outcome:Float, review:Float, speed:Float, relPrice:Int, Genre:Int, blocks:Int, fsk18:int, episode:Int=-1)
		Local obj:TProgramme =New TProgramme
		if episode >= 0
			obj.BaseInit(title, description, TYPE_SERIE)
			obj.isMovie     = 0
			'only add parent of series
			if episode = 0 then ProgSeriesList.AddLast(obj)
		else
			obj.BaseInit(title, description, TYPE_MOVIE)
			obj.isMovie     = 1
			ProgMovieList.AddLast(obj)
		endif
		obj.episodeNumber = episode
		obj.review      = Max(0,review)
		obj.speed       = Max(0,speed)
		obj.relPrice    = Max(0,relPrice)
		obj.Outcome	    = Max(0,Outcome)
		obj.Genre       = Max(0,Genre)
		obj.blocks      = Max(1,blocks)
		obj.fsk18       = fsk18
		obj.actors 		= actors
		obj.director    = director
		obj.country     = country
		obj.year        = year
		obj.livehour    = Max(-1,livehour)
		obj.topicality  = obj.ComputeTopicality()
		obj.maxtopicality = obj.topicality
		ProgList.AddLast(obj)
		Return obj
	End Function


	Method AddEpisode:TProgramme(title:String, description:String, actors:String, director:String, country:String, year:Int, livehour:Int, Outcome:Float, review:Float, speed:Float, relPrice:Int, Genre:Int, blocks:Int, fsk18:int, episode:Int=0, id:Int=0)
		Local obj:TProgramme = New TProgramme
		obj.BaseInit( title, description, TYPE_SERIE | TYPE_EPISODE)
		if review < 0 then obj.review = self.review else obj.review = review
		if speed < 0 then obj.speed = self.speed else obj.speed = speed
		if relPrice < 0 then obj.relPrice = self.relPrice else obj.relPrice = relPrice

		self.episodecount :+1
		obj.episodecount = self.episodecount

		if blocks < 0 then obj.blocks = self.blocks else obj.blocks = blocks
		if year < 0	then obj.year = self.year else obj.year = year
		if livehour < 0	then obj.livehour = self.livehour else obj.livehour = livehour
		if genre < 0 then obj.genre = self.genre else obj.genre = genre
		if actors = "" then obj.actors = self.actors else obj.actors = actors
		if director = "" then obj.director = self.director else obj.director = director
		if country = "" then obj.country = self.country else obj.country = country

		obj.fsk18       = fsk18
		obj.isMovie     = 0
		obj.episodeNumber = episode
		obj.parent = self
		self.episodeList.AddLast(obj)
		ProgList.AddLast(obj)
		Return obj
	End Method

	Function Load:TProgramme(pnode:xmlNode, isEpisode:Int = 0, origowner:Int = 0)
		Local Programme:TProgramme = New TProgramme
		Programme.episodeList = CreateList() ' TObjectList.Create(100)

		Local NODE:xmlNode = pnode.FirstChild()
		While NODE <> Null
			Local nodevalue:String = ""
			If node.HasAttribute("var", False) Then nodevalue = node.Attribute("var").value
			Local typ:TTypeId = TTypeId.ForObject(Programme)
			For Local t:TField = EachIn typ.EnumFields()
				If (t.MetaData("saveload") <> "nosave" Or t.MetaData("saveload") = "normal") And Upper(t.name()) = NODE.name
					t.Set(Programme, nodevalue)
				EndIf
			Next
			Select NODE.name
				Case "EPISODE"
    						     Programme.EpisodeList.AddLast(TProgramme.Load(NODE, 1, Programme.used))
			End Select
			NODE = NODE.nextSibling()
		Wend
		If Programme.episodecount > 0 And Not isEpisode
			' Print "loaded series: "+Programme.title
			TProgramme.ProgSeriesList.AddLast(Programme)
		Else If Not isEpisode
			TProgramme.ProgMovieList.AddLast(Programme)
			'Print "loaded  movie: "+Programme.title
		EndIf
		TProgramme.ProgList.AddLast(Programme)
		If Programme.used > 0 Or Programme.clone Then
			Player[Programme.used].ProgrammeCollection.AddProgramme(Programme, Programme.used)
			'Print "added to player:"+Programme.used + " ("+Programme.title+") Clone:"+Programme.clone + " Time:"+Programme.sendtime
		EndIf
		If isEpisode And origowner > 0 Then
			Player[origowner].ProgrammeCollection.AddProgramme(Programme, origowner)
			'Print "added to player:"+Programme.used
		EndIf
		Return programme
	End Function

  Function LoadAll()
	PrintDebug("TProgramme.LoadAll()", "Lade Programme", DEBUG_SAVELOAD)
    ProgList.Clear()
	ProgMovieList.Clear()
	ProgSeriesList.Clear()
	Local Children:TList = LoadSaveFile.NODE.ChildList
	For Local NODE:xmlNode = EachIn Children
		If NODE.name = "PROGRAMME"
		      TProgramme.Load(NODE)
		End If
	Next
  End Function

	Function SaveAll()
		Local Programme:TProgramme
		Local i:Int = 0
		LoadSaveFile.xmlBeginNode("ALLPROGRAMMES")
			For i = 0 To TProgramme.ProgMovieList.Count()-1
				Programme = TProgramme(TProgramme.ProgMovieList.ValueAtIndex(i))
'				Programme = TProgramme(TProgramme.ProgMovieList.Items[i] )
				If Programme <> Null Then Programme.Save()
			Next
			For i = 0 To TProgramme.ProgSeriesList.Count()-1
'				Programme = TProgramme(TProgramme.ProgSeriesList.Items[i])
				Programme = TProgramme(TProgramme.ProgSeriesList.ValueAtIndex(i))
				If Programme <> Null Then Programme.Save()
			Next
	 	LoadSaveFile.xmlCloseNode()
	End Function

	Method Save(isepisode:Int=0)
	    If Not isepisode Then LoadSaveFile.xmlBeginNode("PROGRAMME")
			Local typ:TTypeId = TTypeId.ForObject(Self)
			For Local t:TField = EachIn typ.EnumFields()
				If t.MetaData("saveload") <> "nosave" Or t.MetaData("saveload") = "normal"
					LoadSaveFile.xmlWrite(Upper(t.name()), String(t.Get(Self)))
				EndIf
			Next
			'SaveFile.WriteInt(Programme.episodeList.Count()-1)
			If Not isepisode
				For Local j:Int = 0 To Self.episodeList.Count()-1
					LoadSaveFile.xmlBeginNode("EPISODE")
						TProgramme(Self.episodeList.ValueAtIndex(j)).Save(True)
'						TProgramme(Self.episodeList.Items[j] ).Save(True)
					LoadSaveFile.xmlCloseNode()
				Next
			EndIf
		If Not isepisode Then LoadSaveFile.xmlCloseNode()
	End Method

	Method Buy()
		Player[Game.playerID].finances[TFinancials.GetDayArray(Game.day)].PayMovie(ComputePrice())
		'DebugLog "Programme "+title +" bought"
	End Method

	Method Sell()
		Player[Game.playerID].finances[TFinancials.GetDayArray(Game.day)].SellMovie(ComputePrice())
		'DebugLog "Programme "+title +" sold"
	End Method

	Function CountGenre:Int(Genre:Int, Liste:TList)
		Local genrecount:Int=0
		For Local movie:TProgramme= EachIn Liste
			If movie.Genre = Genre then genrecount:+1
		Next
		Return genrecount
	End Function

	Function GetProgramme:TProgramme(id:Int)
		For Local i:Int = 0 To ProgList.Count() - 1
			If TProgramme(ProgList.ValueAtIndex(i)) <> Null
				If TProgramme(ProgList.ValueAtIndex(i)).id = id Then Return TProgramme(ProgList.ValueAtIndex(i))
			EndIf
		Next
		Return Null
	End Function

	Function GetMovie:TProgramme(id:Int)
		For Local i:Int = 0 To ProgMovieList.Count() - 1
			If TProgramme(ProgMovieList.ValueAtIndex(i)) <> Null
				If TProgramme(ProgMovieList.ValueAtIndex(i)).id = id Then Return TProgramme(ProgMovieList.ValueAtIndex(i))
			EndIf
		Next
		Return Null
	End Function

	Function GetEpisode:TProgramme(parentprogramme:TProgramme, id:Int)
		If parentprogramme <> Null
			For Local i:Int = 0 To parentprogramme.episodeList.Count() - 1
				If TProgramme(parentprogramme.episodeList.ValueAtIndex(i)).id = id Then Return TProgramme(parentprogramme.episodeList.ValueAtIndex(i))
			Next
		EndIf
		Return Null
	EndFunction

	Function GetSeries:TProgramme(id:Int)
		For Local i:Int = 0 To ProgSeriesList.Count() - 1
			If TProgramme(ProgSeriesList.ValueAtIndex(i)).id = id Then Return TProgramme(ProgSeriesList.ValueAtIndex(i))
		Next
		Return Null
	End Function

	Function GetRandomMovie:TProgramme(playerID:Int = -1)
		Local movie:TProgramme
		Local Count:Int = 0
		Repeat
		  movie = TProgramme(ProgMovieList.ValueAtIndex(Rnd(0, ProgMovieList.Count() - 1)))
		  Count:+1
		Until movie.used = 0 Or Count > 100
		If Count < 100 Then movie.used = playerID;Return movie
		Return Null
	End Function

	Function GetRandomMovieWithMinPrice:TProgramme(MinPrice:Int, playerID:Int = -1)
		Local movie:TProgramme
		Local count:Int=0
		Repeat
		  movie = TProgramme(ProgMovieList.ValueAtIndex(Rnd(0, ProgMovieList.Count() - 1)))
		  count:+1
		Until (movie.ComputePrice() >= MinPrice And movie.used = 0 )Or count > 100
		If Count < 100 Then movie.used = playerID;Return movie
		Return Null
	End Function

	Function GetRandomMovieWithBlocks:TProgramme(playerID:Int = -1, blocks:Int = 0)
		Local movie:TProgramme
		Local count:Int=0
		Repeat
			movie = TProgramme(ProgMovieList.ValueAtIndex((Rnd(0, ProgMovieList.Count() - 1))))
			Count:+1
		Until movie.used = 0 And movie.blocks = blocks
		movie.used = playerID Or Count > 50 'hier spaeter auf playerid
		Return movie
	End Function

	Function GetRandomSerie:TProgramme(playerID:Int = -1)
		Local serie:TProgramme
		Local count:Int=0
		Repeat
			serie = TProgramme(ProgSeriesList.ValueAtIndex((Rnd(0, ProgSeriesList.Count() - 1))))
			Count:+1
		Until serie.used = 0 Or Count > 100
		If Count < 100
			serie.used = playerID
			Return serie
		endif
		'print "KEINE SERIE FÜR "+playerID+" verfügbar"
		Return Null
	End Function

	Method GetGenre:String(_genre:Int=-1)
		if _genre > 0 then Return GetLocale("MOVIE_GENRE_" + _genre)
		Return GetLocale("MOVIE_GENRE_" + self.genre)
	End Method

	Method ComputeTopicality:Float()
		If topicality < 0 then Return Max(0, (255 - 2 * (Game.year - year)) )   'simplest form ;D
		Return topicality
	End Method

 'computes a percentage which could be multiplied with maxaudience
 Method ComputeAudienceQuote:Float(lastquote:Float=0)
    Local quote:Float =0.0
    Local singleprice:Int = 0
    singleprice = ComputePrice()
    If episodecount > 0 Then singleprice = singleprice / episodecount
    quote = 0.25*lastquote + 0.2*Outcome/255 + 0.15*review/255 + 0.1*speed/255 + 0.2*ComputeTopicality()/255 + 0.1*(RandRange(1,254)+1)/255
    Return quote * Game.maxAudiencePercentage
 End Method

	Method RefreshTopicality:Int()
		topicality = Min(topicality*1.5, maxtopicality)
		Return topicality
	End Method

	Method ComputePrice:Int()
		Local value:Float
		Local tmpreview:Float
		Local tmpspeed:Float

		if self.episodeList.count() > 0
			for local episode:TProgramme = eachin self.episodeList
				value :+ episode.ComputePrice()
			Next
			value :* 0.75
		else
			If Outcome > 0 'movies
				value = 0.45 * 255 * Outcome + 0.25 * 255 * review + 0.3 * 255 * speed
				If (maxTopicality > 220) Then value:*1.5
				If (maxTopicality > 240) Then value:*1.5
			Else 'shows, productions, series...
				value = 0.4 * 255 * review + 0.6 * 255 * speed
				tmpreview = 1.6667 * review
				If (review > 0.5 * 255) Then tmpreview = 255 - 2.5 * (review - 0.5 * 255)
				tmpspeed = 1.6667 * speed
				If (speed > 0.6 * 255) Then tmpspeed = 255 - 2.5 * (speed - 0.6 * 255)
				value = 0.4 * 255 * tmpreview + 0.6 * 255 * tmpspeed
			EndIf
			value:*(3 * ComputeTopicality() / 255)
			value = Int(Floor(value / 1000) * 1000)
		endif
		return value
	End Method

	Method ShowSheet:Int(x:Int,y:Int, plannerday:Int = -1, series:TProgramme=null)
		Local widthbarspeed:Float		= Float(speed / 255)
		Local widthbarreview:Float		= Float(review / 255)
		Local widthbaroutcome:Float		= Float(Outcome/ 255)
		Local widthbartopicality:Float	= Float(Float(topicality) / 255)
		local normalFont:TBitmapFont	= FontManager.baseFont

		local dY:int = 0

		If isMovie
			gfx_datasheets_movie.render(x,y)
			FontManager.basefontBold.DrawBlock(title, x + 10, y + 11, 278, 20)
		else
			gfx_datasheets_series.render(x,y)
			'episode display
			if series <> null
				FontManager.basefontBold.DrawBlock(series.title, x + 10, y + 11, 278, 20)
				normalFont.DrawBlock("(" + episodeNumber + "/" + series.episodecount + ") " + title, x + 10, y + 34, 278, 20, 0)  'prints programmedescription on moviesheet
			else
				FontManager.basefontBold.DrawBlock(title, x + 10, y + 11, 278, 20)
				normalFont.DrawBlock(episodecount+" "+GetLocale("MOVIE_EPISODES") , x+10,  y+34 , 278, 20,0) 'prints programmedescription on moviesheet
			endif

			dy :+ 22
		endif
		If self.fsk18 <> 0 then normalFont.DrawBlock(GetLocale("MOVIE_XRATED") , x+240 , y+dY+34 , 50, 20,0) 'prints pg-rating

		normalFont.DrawBlock(description      , x+10,  y+dy+56 , 278, 70,0) 'prints programmedescription on moviesheet
		normalFont.DrawBlock(GetLocale("MOVIE_DIRECTOR")+":", x+10 , y+dY+135, 280, 16,0)
		normalFont.DrawBlock(GetLocale("MOVIE_ACTORS")+":"  , x+10 , y+dY+148, 280, 32,0)
		normalFont.DrawBlock(GetLocale("MOVIE_SPEED")       , x+222, y+dY+187, 280, 16,0)
		normalFont.DrawBlock(GetLocale("MOVIE_CRITIC")      , x+222, y+dY+210, 280, 16,0)
		normalFont.DrawBlock(GetLocale("MOVIE_BOXOFFICE")   , x+222, y+dY+233, 280, 16,0)
		normalFont.DrawBlock(director         , x+10 +5+ normalFont.getWidth(GetLocale("MOVIE_DIRECTOR")+":") , y+dY+135, 280-15-normalFont.getWidth(GetLocale("MOVIE_DIRECTOR")+":"), 16,0) 	'prints director
		normalFont.DrawBlock(actors           , x+10 +5+ normalFont.getWidth(GetLocale("MOVIE_ACTORS")+":"), y+dY+148, 280-15-normalFont.getWidth(GetLocale("MOVIE_ACTORS")+":"), 32,0) 	'prints actors
		normalFont.DrawBlock(GetGenre(Genre)  , x+78 , y+dY+35 , 150, 16,0) 	'prints genre
		normalFont.DrawBlock(country          , x+10 , y+dY+35 , 150, 16,0)		'prints country
		normalFont.DrawBlock(year		      , x+36 , y+dY+35 , 150, 16,0) 	'prints year

		normalFont.DrawBlock(GetLocale("MOVIE_TOPICALITY")  , x+84, y+281, 40, 16,0)
		normalFont.DrawBlock(GetLocale("MOVIE_BLOCKS")+": "+blocks, x+10, y+281, 100, 16,0)
		normalFont.DrawBlock(ComputePrice(), x+240, y+281, 120, 20,0)


		If widthbarspeed  >0.01 then Assets.GetSprite("gfx_datasheets_bar").DrawClipped(x+13 - 200 + widthbarspeed*200,	y+dY+188,		x+13, y+dY+187, 200, 12)
		If widthbarreview >0.01 then Assets.GetSprite("gfx_datasheets_bar").DrawClipped(x+13 - 200 + widthbarreview*200,y+dY+210,		x+13, y+dY+209, 200, 12)
		If widthbaroutcome>0.01 then Assets.GetSprite("gfx_datasheets_bar").DrawClipped(x+13 - 200 + widthbaroutcome*200,y+dY+232,		x+13, y+dY+231, 200, 12)
		If widthbartopicality>0.01 then Assets.GetSprite("gfx_datasheets_bar").DrawClipped(x+115 - 200 + widthbartopicality*100,y+280,	x+115, y+279, 100,12)
	End Method
 End Type

Type TNews extends TProgrammeElement
  Field Genre:Int
  Field quality:Int
  Field price:Int
  Field episodecount:Int = 0
  Field episode:Int = 0
  Field episodeList:TList 	{saveload="special"}
  Field happenedday:Int = -1
  Field happenedhour:Int = -1
  Field happenedminute:Int = -1
  Field parent:TNews = Null
  Field used : Int = 0  										'event happened, so this news is not repeated until every else news is used
  Global LastUniqueID:Int = 0 {saveload="special"}
  Global List:TList = CreateList()								'holding only first chain of news (start)
  Global NewsList:TList = CreateList()  {saveload="special"}	'holding all news


	Function Load:TNews(pnode:xmlNode, isEpisode:Int = 0, origowner:Int = 0)
		Local News:TNews = New TNews
		Local ParentNewsID:Int = -1
		News.episodeList = CreateList() ' TObjectList.Create(100)

		Local NODE:xmlNode = pnode.FirstChild()
		While NODE <> Null
			Local nodevalue:String = ""
			If node.HasAttribute("var", False) Then nodevalue = node.Attribute("var").value
			Local typ:TTypeId = TTypeId.ForObject(News)
			For Local t:TField = EachIn typ.EnumFields()
				If (t.MetaData("saveload") <> "nosave" And t.MetaData("saveload") <> "special") And Upper(t.name()) = NODE.name
					t.Set(News, nodevalue)
				EndIf
			Next
			Select NODE.name
				Case "LASTUNIQUEID"	TNews.LastUniqueID = Int(node.Attribute("var").Value)
				Case "PARENTNEWSID"	ParentNewsID = Int(node.Attribute("var").Value)
				Case "EPISODE"		News.EpisodeList.AddLast(TNews.Load(NODE, 1))
			End Select
			NODE = NODE.nextSibling()
		Wend
	  	If ParentNewsID >= 0 Then news.parent = TNews.GetNews(parentNewsID)
   	    TNews.NewsList.AddLast(news)
		If Not IsEpisode Then TNews.List.AddLast(news)
		Return news
	End Function

	Function LoadAll()
		PrintDebug("TNews.LoadAll()", "Lade News", DEBUG_SAVELOAD)
		TNews.List.Clear()
	    TNews.NewsList.Clear()
		Local Children:TList = LoadSaveFile.NODE.ChildList
		For Local node:xmlNode = EachIn Children
			If NODE.name = "ALLNEWS"
			      TNews.Load(NODE)
			End If
		Next
	End Function

	Function SaveAll()
		Local i:Int = 0
		LoadSaveFile.xmlBeginNode("ALLNEWS")
			LoadSaveFile.xmlWrite("LASTUNIQUEID",	TNews.LastUniqueID)
			For i = 0 To TNews.List.Count()-1
				Local news:TNews = TNews(TNews.List.ValueAtIndex(i))
				If news <> Null Then news.Save()
			Next
		LoadSaveFile.xmlCloseNode()
	End Function

	Method Save(isEpisode:Int=0)
	    If Not isepisode Then LoadSaveFile.xmlBeginNode("NEWS")
			Local typ:TTypeId = TTypeId.ForObject(Self)
			For Local t:TField = EachIn typ.EnumFields()
				If t.MetaData("saveload") <> "special" Or t.MetaData("saveload") = "normal"
					LoadSaveFile.xmlWrite(Upper(t.name()), String(t.Get(Self)))
				EndIf
			Next
			If Not isepisode
				For Local j:Int = 0 To Self.episodeList.Count()-1
					LoadSaveFile.xmlBeginNode("EPISODE")
						TNews(Self.episodeList.ValueAtIndex(j)).Save(True)
					LoadSaveFile.xmlCloseNode()
				Next
			EndIf
		If Not isepisode Then LoadSaveFile.xmlCloseNode()
	End Method


	Function CountGenre:Int(Genre:Int, Liste:TList)
		Local genrecount:Int=0
		For Local news:TNews= EachIn Liste
			If news.Genre = Genre genrecount:+1
		Next
		Return genrecount
	End Function

	Function GetRandomNews:TNews()
		Local news:TNews = Null
		Local allsent:Int = 0
		Repeat news = TNews(List.ValueAtIndex((Rnd(0, List.Count() - 1))))
			allsent:+1
		Until news.used = 0 Or allsent > 250
		If allsent > 250
			For Local i:Int = 0 To List.Count()-1
				news = TNews(List.ValueAtIndex(i))
				If news <> Null Then news.used = 0
			Next
			Print "NEWS: allsent > 250... reset"
			news = TNews(List.ValueAtIndex((Rnd(0, List.Count() - 1))))
		EndIf
		news.happenedday = game.day
		news.happenedhour = game.GetActualHour()
		news.happenedminute = game.GetActualMinute()
		news.used = 1
		Print "get random news: "+news.title
		Return news
	End Function

	Function GetGenre:String(Genre:Int)
		If Genre = 0 Then Return GetLocale("NEWS_POLITICS_ECONOMY")
		If Genre = 1 Then Return GetLocale("NEWS_SHOWBIZ")
		If Genre = 2 Then Return GetLocale("NEWS_SPORT")
		If Genre = 3 Then Return GetLocale("NEWS_TECHNICS_MEDIA")
		If Genre = 4 Then Return GetLocale("NEWS_CURRENTAFFAIRS")
		Return Genre+ " unbekannt"
	End Function

	Method ComputeTopicality:Float()
		return Max(0, Int(255-10*((Game.day*10000+game.GetActualHour()*100+game.GetActualMinute()) - (happenedday*10000+happenedhour*100+happenedminute))/100) )'simplest form ;D
	End Method

	'computes a percentage which could be multiplied with maxaudience
	Method ComputeAudienceQuote:Float(lastquote:Float=0)
		Local quote:Float =0.0
		If lastquote < 0 Then lastquote = 0
			quote = 0.1*lastquote + 0.35*((quality+5)/255) + 0.5*ComputeTopicality()/255 + 0.05*(Rand(254)+1)/255
		Return quote * Game.maxAudiencePercentage
	End Method

	Method ComputePrice:Int()
		Return Floor(Float(quality * price / 100 * 2 / 5)) * 100 + 1000  'Teuerstes in etwa 10000+1000
	End Method

	Function Create:TNews(title:String, description:String, Genre:Int, episode:Int=0, quality:Int=0, price:Int=0, id:Int=0)
		Local LocObject:TNews =New TNews
		LocObject.BaseInit(title, description, TYPE_NEWS)
		LocObject.title       = title
		LocObject.description = description
		LocObject.Genre       = Genre
		LocObject.episode     = episode
		Locobject.quality     = quality
		Locobject.price       = Rand(80,100)

		LocObject.episodeList = CreateList()
		List.AddLast(LocObject)
		NewsList.AddLast(LocObject)
		Return LocObject
	End Function

	Method AddEpisode:TNews(title:String, description:String, Genre:Int, episode:Int=0,quality:Int=0, price:Int=0, id:Int=0)
		Local obj:TNews =New TNews
		obj.BaseInit(title, description, TYPE_NEWS)
		obj.Genre       = Genre
		obj.quality     = quality
		obj.price       = price

		self.episodecount :+ 1
	    obj.episode     = episode
		obj.parent		= Self

		self.episodeList.AddLast(obj)
		SortList(self.episodeList)
		NewsList.AddLast(obj)
		Return obj
	End Method

	'returns Parent (first) of a random NewsChain	(genre -1 is random)
	'Important: only unused (happenedday = -1 or older than X days)
	Function GetRandomChainParent:TNews(Genre:Int=-1)
		Local allsent:Int =0
		Local news:TNews=Null
		Repeat news = TNews(List.ValueAtIndex(Rnd(0, List.Count() - 1)))
			allsent:+1
		Until news.used = 0 Or allsent > 250
		If allsent > 250 Then news = TNews(List.ValueAtIndex(Rnd(0, List.Count() - 1)))

		news.happenedday = game.day
		news.happenedhour = game.GetActualHour()
		news.happenedminute = game.GetActualMinute()
		news.used = 1
		Return news
	EndFunction

  'returns the next news out of a chain, params are the currentnews
  'Important: only unused (happenedday = -1 or older than X days)
  Function GetNextInNewsChain:TNews(currentNews:TNews, isParent:Int=0)
    Local news:TNews=Null
    If currentNews <> Null
      If Not isParent Then news = TNews(currentNews.parent.episodeList.ValueAtIndex(currentnews.episode -1))
      If     isParent Then news = TNews(currentNews.episodeList.ValueAtIndex(0))
      news.happenedday		= game.day
      news.happenedhour		= game.GetActualHour()
      news.happenedminute	= game.GetActualMinute()
      news.used				= 1
      Return news
    EndIf
  EndFunction

 Function GetNews:TNews(number:Int)
   Local news:TNews = Null
   For Local i:Int = 0 To TNews.List.Count()-1
     news = TNews(TNews.List.ValueAtIndex(i))
'     news = TNews(TNews.List.Items[ i ])
	 If news <> Null
  	   If news.id = number
         news.happenedday = Game.day
  	     news.happenedhour = Game.GetActualHour()
  	     news.happenedminute = Game.GetActualMinute()
	     Return news
	   EndIf
	 EndIf
   Next
   Return Null
 End Function
End Type

Type TDatabase
	Field file:String
	Field moviescount:Int
	Field totalmoviescount:Int
	Field seriescount:Int
	Field newscount:Int
	Field totalnewscount:Int
	Field contractscount:Int

	Function Create:TDatabase()
		Local Database:TDatabase=New TDatabase
		Database.file				= ""
		Database.moviescount   		= 0
		Database.totalmoviescount	= 0
		Database.seriescount		= 0
		Database.newscount			= 0
		Database.contractscount		= 0
		Return Database
	End Function


	Method Load(filename:String)
		Local title:String
		Local description:String
		Local actors:String
		Local director:String
		Local land:String
		Local year:Int
		Local Genre:Int
		Local duration:Int
		Local fsk18:int
		Local price:Int
		Local review:Int
		Local speed:Int
		Local Outcome:Int
		Local livehour:Int

		Local daystofinish:Int
		Local spotcount:Int
		Local targetgroup:Int
		Local minaudience:Int
		Local profit:Int
		Local penalty:Int

		Local quality:Int


		local xml:TXmlHelper = TXmlHelper.Create(filename)
		local nodeParent:TxmlNode
		local nodeChild:TxmlNode
		local nodeEpisode:TxmlNode
		local listChildren:TList
		local loadError:string = ""



		'---------------------------------------------
		'importing all movies
		nodeParent		= xml.FindRootChild("allmovies")
		loadError		= "Problems loading movies. Check database.xml"
		if nodeParent <> null
			listChildren = nodeParent.getChildren()
			if listChildren = null then throw loadError

			for nodeChild = eachIn listChildren
				If nodeChild.getName() = "movie"
					xml.setNode(nodeChild)
					title       = xml.FindValue("title", "unknown title")
					description = xml.FindValue("description", "23")
					actors      = xml.FindValue("actors", "")
					director    = xml.FindValue("director", "")
					land        = xml.FindValue("country", "UNK")
					year 		= xml.FindValueInt("year", 1900)
					Genre 		= xml.FindValueInt("genre", 0 )
					duration    = xml.FindValueInt("blocks", 2)
					fsk18 		= xml.FindValueInt("xrated", 0)
					price 		= xml.FindValueInt("price", 0)
					review 		= xml.FindValueInt("critics", 0)
					speed 		= xml.FindValueInt("speed", 0)
					Outcome 	= xml.FindValueInt("outcome", 0)
					livehour 	= xml.FindValueInt("time", 0)
					If duration < 0 Or duration > 12 Then duration =1
					TProgramme.Create(title,description,actors, director,land, year, livehour, Outcome, review, speed, price, Genre, duration, fsk18, -1)
					'print "film: "+title+ " " + Database.totalmoviescount
					Database.totalmoviescount :+ 1
				EndIf
			Next
		else
			throw loadError
		endif

		'---------------------------------------------
		'importing all series including their episodes
		nodeParent		= xml.FindRootChild("allseries")
		loadError		= "Problems loading series. Check database.xml"
		if nodeParent = null then throw loadError
		listChildren = nodeParent.getChildren()
		if listChildren = null then throw loadError
		for nodeChild = eachIn listChildren
			If nodeChild.getName() = "serie"
				'load series main data
				xml.setNode(nodeChild)
				title       = xml.FindValue("title", "unknown title")
				description = xml.FindValue("description", "")
				actors      = xml.FindValue("actors", "")
				director    = xml.FindValue("director", "")
				land        = xml.FindValue("country", "UNK")
				year 		= xml.FindValueInt("year", 1900)
				Genre 		= xml.FindValueInt("genre", 0)
				duration    = xml.FindValueInt("blocks", 2)
				fsk18 		= xml.FindValueInt("xrated", 0)
				price 		= xml.FindValueInt("price", -1)
				review 		= xml.FindValueInt("critics", -1)
				speed 		= xml.FindValueInt("speed", -1)
				Outcome 	= xml.FindValueInt("outcome", -1)
				livehour 	= xml.FindValueInt("time", -1)
				If duration < 0 Or duration > 12 Then duration =1
				local parent:TProgramme = TProgramme.Create(title,description,actors, director,land, year, livehour, Outcome, review, speed, price, Genre, duration, fsk18, 0)
				Database.seriescount :+ 1

				'load episodes
				local EpisodeNum:int = 0
				local listEpisodes:TList = nodeChild.getChildren()
				if listEpisodes <> null AND listEpisodes.count() > 0
					for nodeEpisode = eachIn listEpisodes
						If nodeEpisode.getName() = "episode"
							xml.setNode(nodeEpisode)
							EpisodeNum	= xml.FindValueInt("number", EpisodeNum+1)
							title      	= xml.FindValue("title", "")
							description = xml.FindValue("description", description)
							actors      = xml.FindValue("actors", "")
							director    = xml.FindValue("director", "")
							land        = xml.FindValue("country", "")
							year 		= xml.FindValueInt("year", -1)
							Genre 		= xml.FindValueInt("genre", -1)
							duration    = xml.FindValueInt("blocks", -1)
							fsk18 		= xml.FindValueInt("xrated", fsk18)
							price 		= xml.FindValueInt("price", -1)
							review 		= xml.FindValueInt("critics", -1)
							speed 		= xml.FindValueInt("speed", -1)
							Outcome 	= xml.FindValueInt("outcome", -1)
							livehour	= xml.FindValueInt("time", -1)
							'add episode to last added serie
							'print "serie: --- episode:"+duration + " " + title
							parent.AddEpisode(title,description,actors, director,land, year, livehour, Outcome, review, speed, price, Genre, duration, fsk18, EpisodeNum)
						EndIf
					Next
				Endif
			Endif
		Next

		'---------------------------------------------
		'importing all ads
		nodeParent		= xml.FindRootChild("allads")
		loadError		= "Problems loading ads. Check database.xml"
		if nodeParent = null then throw loadError

		listChildren = nodeParent.getChildren()
		if listChildren = null then throw loadError
		for nodeChild = eachIn listChildren
			If nodeChild.getName() = "ad"
				xml.setNode(nodeChild)
				title       = xml.FindValue("title", "unknown title")
				description = xml.FindValue("description", "")
				targetgroup = xml.FindValueInt("targetgroup", 0)
				spotcount	= xml.FindValueInt("repetitions", 1)
				minaudience	= xml.FindValueInt("minaudience", 0)
				profit	    = xml.FindValueInt("profit", 0)
				penalty		= xml.FindValueInt("penalty", 0)
				daystofinish= xml.FindValueInt("time", 1)

				TContract.Create(title, description, daystofinish, spotcount, targetgroup, minaudience, profit, penalty, Database.contractscount)
				'print "contract: "+title+ " " + Database.contractscount
				Database.contractscount :+ 1
			EndIf
		Next


		'---------------------------------------------
		'importing all news including their chains
		nodeParent		= xml.FindRootChild("allnews")
		loadError		= "Problems loading news. Check database.xml"
		if nodeParent = null then throw loadError
		listChildren = nodeParent.getChildren()
		if listChildren = null then throw loadError
		for nodeChild = eachIn listChildren
			If nodeChild.getName() = "news"
				'load series main data
				xml.setNode(nodeChild)
				title       = xml.FindValue("title", "unknown newstitle")
				description	= xml.FindValue("description", "")
				genre		= xml.FindValueInt("genre", 0)
				quality		= xml.FindValueInt("topicality", 0)
				price		= xml.FindValueInt("price", 0)
				local parentNews:TNews = TNews.Create(title, description, Genre, Database.totalnewscount,quality, price, 0)

				'load episodes
				local EpisodeNum:int = 0
				local listEpisodes:TList = nodeChild.getChildren()
				if listEpisodes <> null AND listEpisodes.count() > 0
					for nodeEpisode = eachIn listEpisodes
						If nodeEpisode.getName() = "episode"
							xml.setNode(nodeEpisode)
							EpisodeNum		= xml.FindValueInt("number", EpisodeNum+1)
							title			= xml.FindValue("title", "unknown Newstitle")
							description		= xml.FindValue("description", "")
							genre			= xml.FindValueInt("genre", genre)
							quality			= xml.FindValueInt("topicality", quality)
							price			= xml.FindValueInt("price", price)
							parentNews.AddEpisode(title,description, Genre, EpisodeNum,quality, price, Database.totalnewscount)
							Database.totalnewscount :+1
						EndIf
					Next
					Database.newscount :+ 1
					Database.totalnewscount :+1
				EndIf
			Endif
		Next

		print("found " + Database.seriescount+ " series, "+Database.totalmoviescount+ " movies, "+ Database.contractscount + " advertisements, " + Database.totalnewscount + " news")
	End Method
End Type





Type TAdBlock Extends TBlockGraphical
	Field State:Int 				= 0			{saveload = "normal"}
    Field timeset:Int 				=-1			{saveload = "normal"}
    Field Height:Int							{saveload = "normal"}
    Field width:Int								{saveload = "normal"}
    Field botched:Int				= 0			{saveload = "normal"}   		 'contract-audience reached or not
    Field blocks:Int				= 1			{saveload = "normal"}
    Field senddate:Int				=-1			{saveload = "normal"} 			 'which day this ad is planned to be send?
    Field sendtime:Int				=-1			{saveload = "normal"}			 'which time this ad is planned to be send?
    Field contract:TContract
    Field id:Int					= 0			{saveload = "normal"}
	Field Link:TLink
    Global LastUniqueID:Int			= 0
    Global DragAndDropList:TList
    Global List:TList = CreateList()

    Global spriteBaseName:string = "pp_adblock1"

  Function LoadAll(loadfile:TStream)
    TAdBlock.List.Clear()
	Print "cleared adblocklist:"+TAdBlock.List.Count()
    Local BeginPos:Int = Stream_SeekString("<ADB/>",loadfile)+1
    Local EndPos:Int = Stream_SeekString("</ADB>",loadfile)  -6
    Local strlen:Int = 0
    loadfile.Seek(BeginPos)

	TAdBlock.lastUniqueID:Int        = ReadInt(loadfile)
    TAdBlock.AdditionallyDragged:Int = ReadInt(loadfile)
	Repeat
      Local AdBlock:TAdBlock= New TAdBlock
	  AdBlock.state    = ReadInt(loadfile)
	  AdBlock.dragable = ReadInt(loadfile)
	  AdBlock.dragged = ReadInt(loadfile)
	  AdBlock.StartPos.Load(Null)
	  AdBlock.timeset   = ReadInt(loadfile)
	  AdBlock.height   = ReadInt(loadfile)
	  AdBlock.width   = ReadInt(loadfile)
	  AdBlock.botched = ReadInt(loadfile)
	  AdBlock.blocks   = ReadInt(loadfile)
	  AdBlock.senddate = ReadInt(loadfile)
	  AdBlock.sendtime = ReadInt(loadfile)
	  AdBlock.owner    = ReadInt(loadfile)
	  Local ContractID:Int = ReadInt(loadfile)
      If ContractID >= 0
	    Local contract:TContract = New TContract
		contract = TContract.Load(Null) 'loadfile)
        AdBlock.contract = New TContract
 	    AdBlock.contract = Player[AdBlock.owner].ProgrammePlan.CloneContract(contract)
 	    AdBlock.contract.owner = AdBlock.owner
        AdBlock.contract.senddate = contract.senddate
        AdBlock.contract.sendtime = contract.sendtime
 	    AdBlock.contract.spotnumber = Adblock.GetPreviousContractCount()
	  EndIf
		AdBlock.Pos.Load(Null)
	  AdBlock.id = ReadInt(loadfile)
	  AdBlock.Link = TAdBlock.List.AddLast(AdBlock)
	  ReadString(loadfile,5) 'finishing string (eg. "|PRB|")
	  Player[AdBlock.owner].ProgrammePlan.AddContract(AdBlock.contract)
	Until loadfile.Pos() >= EndPos
	Print "loaded adblocklist"
  End Function

	Function SaveAll()
		LoadSaveFile.xmlBeginNode("ALLADBLOCKS")
			LoadSaveFile.xmlWrite("LASTUNIQUEID", 			TAdBlock.LastUniqueID)
			LoadSaveFile.xmlWrite("ADDITIONALLYDRAGGED", 	TAdBlock.AdditionallyDragged)
			For Local AdBlock:TAdBlock= EachIn TAdBlock.List
				If AdBlock <> Null Then AdBlock.Save()
			Next
		LoadSaveFile.xmlCloseNode()
	End Function

	Method Save()
		LoadSaveFile.xmlBeginNode("ADBLOCK")
			Local typ:TTypeId = TTypeId.ForObject(Self)
			For Local t:TField = EachIn typ.EnumFields()
				If t.MetaData("saveload") = "normal"
					LoadSaveFile.xmlWrite(Upper(t.name()), String(t.Get(Self)))
				EndIf
			Next
			If Self.contract <> Null
				LoadSaveFile.xmlWrite("CONTRACTID", 	Self.contract.id)
				Self.contract.Save()
			Else
				LoadSaveFile.xmlWrite("CONTRACTID", 	"-1")
			EndIf
		LoadSavefile.xmlCloseNode()
	End Method

	Function Create:TAdBlock(x:Int = 0, y:Int = 0, owner:Int = 0, contractpos:Int = -1)
		Local AdBlock:TAdBlock=New TAdBlock
		AdBlock.Pos 		= TPosition.Create(x, y)
		AdBlock.StartPos	= TPosition.Create(x, y)
		Adblock.owner = owner
		AdBlock.blocks = 1
		AdBlock.State = 0
		Adblock.id = TAdBlock.LastUniqueID
		TAdBlock.LastUniqueID :+1

		'hier noch als variablen uebernehmen
		AdBlock.dragable = 1
		AdBlock.width = Assets.GetSprite("pp_adblock1").w
		AdBlock.Height = Assets.GetSprite("pp_adblock1").h
		AdBlock.senddate = Game.day
		AdBlock.sendtime = AdBlock.GetTimeOfBlock()

		Local _contract:TContract
		If contractpos <= -1
			_contract = Player[owner].ProgrammeCollection.GetLocalRandomContract()
		Else
			SortList(Player[owner].ProgrammeCollection.ContractList)
			_contract = TContract(Player[owner].ProgrammeCollection.ContractList.ValueAtIndex(contractPos-1))
		EndIf
		AdBlock.contract			= Player[owner].ProgrammePlan.CloneContract(_contract)
		AdBlock.contract.owner		= owner
		AdBlock.contract.spotnumber	= Player[owner].ProgrammePlan.GetPreviousContractCount(AdBlock.contract)
		AdBlock.contract.senddate	= Game.day
		AdBlock.contract.sendtime	= Int(Floor((Adblock.StartPos.y - 17) / 30))

		Adblock.Link = List.AddLast(AdBlock)
		SortList(List)
		Player[owner].ProgrammePlan.AddContract(AdBlock.contract)
		Return AdBlock
	End Function

	Function CreateDragged:TAdBlock(contract:TContract, owner:Int=-1)
	  Local playerID:Int =0
	  If owner < 0 Then playerID = game.playerID Else playerID = owner
	  Local AdBlock:TAdBlock=New TAdBlock
 	  AdBlock.Pos 			= TPosition.Create(MouseX(), MouseY())
 	  AdBlock.StartPos		= TPosition.Create(0, 0)
 	  AdBlock.owner 		= playerID
 	  AdBlock.State 		= 0
 	  Adblock.id			= TAdBlock.LastUniqueID
 	  TAdBlock.LastUniqueID :+1
 	  AdBlock.dragable 		= 1
 	  AdBlock.width 		= Assets.GetSprite("pp_adblock1").w
 	  AdBlock.Height		= Assets.GetSprite("pp_adblock1").h
 	  AdBlock.senddate 		= Game.daytoplan
      AdBlock.sendtime 		= 100

 	  AdBlock.contract				= Player[playerID].ProgrammePlan.CloneContract(contract)
 	  AdBlock.contract.owner		= playerID
 	  AdBlock.contract.spotnumber 	= Adblock.GetPreviousContractCount()
  	  Adblock.dragged 				= 1
	  Adblock.Link 					= List.AddLast(AdBlock)
	  SortList(TAdBlock.List)
 	  Return Adblock
	End Function

	Function GetActualAdBlock:TAdBlock(playerID:Int = -1, time:Int = -1, day:Int = -1)
		If playerID = -1 Then playerID = Game.playerID
		If time = -1 Then time = Game.GetActualHour()
		If day = -1 Then day = Game.day

		For Local Obj:TAdBlock = EachIn TAdBlock.list
			If Obj.owner = playerID
				If (Obj.sendtime) = time And Obj.senddate = day Then Return Obj
			EndIf
  		Next
		Return Null
  	End Function

	Method SetDragable(_dragable:Int = 1)
		dragable = _dragable
	End Method

    Method Compare:Int(otherObject:Object)
       Local s:TAdBlock = TAdBlock(otherObject)
       If Not s Then Return 1                  ' Objekt nicht gefunden, an das Ende der Liste setzen
        Return (10000*dragged + (sendtime + 25*senddate))-(10000*s.dragged + (s.sendtime + 25*s.senddate))
    End Method


	Method GetBlockX:Int(time:Int)
		If time < 12 Then Return 67 + Assets.GetSprite("pp_programmeblock1").w
		Return 394 + Assets.GetSprite("pp_programmeblock1").w
	End Method

	Method GetBlockY:Int(time:Int)
		If time < 12 Then Return time * 30 + 17
		Return (time - 12) * 30 + 17
	End Method

    Method GetTimeOfBlock:Int(_x:Int = 1000, _y:Int = 1000)
		If StartPos.x = 589
    	  Return 12+(Int(Floor(StartPos.y - 17) / 30))
		Else If StartPos.x = 262
    	  Return 1*(Int(Floor(StartPos.y - 17) / 30))
    	EndIf
    	Return -1
    End Method

    'draw the Adblock inclusive text
    'zeichnet den Programmblock inklusive Text
    Method Draw()
		'Draw dragged Adblockgraphic
		If dragged = 1 Or senddate = Game.daytoplan 'out of gameplanner
			State = 1
			If Game.day > Game.daytoplan Then State = 4
			If Game.day < Game.daytoplan Then State = 0
			If Game.day = Game.daytoplan
				If GetTimeOfBlock() > (Int(Floor((Game.minutesOfDayGone-55) / 60))) Then State = 0  'normal
				If GetTimeOfBlock() = (Int(Floor((Game.minutesOfDayGone-55) / 60))) Then State = 2  'running
				If GetTimeOfBlock() < (Int(Floor((Game.minutesOfDayGone) / 60)))    Then State = 1  'runned
				If GetTimeOfBlock() < 0      									    Then State = 0  'normal
			EndIf

			If State = 0 Then SetColor 255,255,255;dragable=1  'normal
			If State = 1 Then SetColor 200,255,200;dragable=0  'runned
			If State = 2 Then SetColor 250,230,120;dragable=0  'running
			If State = 4 Then SetColor 255,255,255;dragable=0  'old day

			local variant:string = ""
			If dragged = 1 And State = 0
				If TAdBlock.AdditionallyDragged >0 Then SetAlpha 1- (1/TAdBlock.AdditionallyDragged * 0.25)
				variant = "_dragged"
			EndIf
			Assets.GetSprite("pp_adblock1"+variant).Draw(Pos.x, Pos.y)

			'draw graphic

			SetColor 0,0,0
			FontManager.baseFontBold.DrawBlock(self.contract.title, pos.x + 3, pos.y+3, self.width, 18, 0, 0, 0, 0, True)
			SetColor 80,80,80
			local text:string = (contract.spotnumber)+"/"+contract.spotcount
			If State = 1 And contract.spotnumber = contract.spotcount
				text = "- OK -"
			ElseIf contract.botched=1
				text = "------"
			EndIf
			FontManager.baseFont.Draw(text ,Pos.x+5,Pos.y+18)
			SetColor 255,255,255 'eigentlich alte Farbe wiederherstellen
			SetAlpha 1.0
		EndIf 'same day or dragged
    End Method

	Function DrawAll(origowner:Int)
      'SortList TAdBlock.List
	  SortList(TAdBlock.List)
      For Local AdBlock:TAdBlock = EachIn TAdBlock.List
        If origowner = Adblock.owner ' or Adblock.owner = Game.playerID
     	  AdBlock.Draw()
        EndIf
      Next
	End Function

	Function UpdateAll(origowner:Int)
      Local gfxListenabled:Byte = 0
      Local havetosort:Byte = 0
      Local number:Int = 0
      If PPprogrammeList.enabled <> 0 Or PPcontractList.enabled <> 0 Then gfxListenabled = 1

      'SortList TAdBlock.List
	  SortList(TAdBlock.List)
      For Local AdBlock:TAdBlock = EachIn TAdBlock.List
      If Adblock.owner = Game.playerID And origowner = game.playerID
        number :+ 1
        If AdBlock.dragged = 1 Then AdBlock.timeset = -1; AdBlock.contract.senddate = Game.daytoplan
        If PPprogrammeList.enabled=0 And MOUSEMANAGER.IsHit(2) And AdBlock.dragged = 1
'          Game.IsMouseRightHit = 0
          For Local i:Byte = 0 To AdBlock.blocks
		    TDragAndDrop.SetDragAndDropTargetState(0, AdBlock.DragAndDropList, TPosition.Create(AdBlock.StartPos.x, AdBlock.StartPos.y+i*30))
          Next
          ReverseList TAdBlock.List
          Adblock.RemoveBlock()
          Adblock.Link.Remove()
		  havetosort = 1
          ReverseList TAdBlock.List
          AdBlock.GetPreviousContractCount()
          MOUSEMANAGER.resetKey(2)
        EndIf
		If Adblock.dragged And Adblock.StartPos.x>0 And Adblock.StartPos.y >0
		 If Adblock.GetTimeOfBlock() < game.GetActualHour() Or (Adblock.GetTimeOfBlock() = game.GetActualHour() And game.GetActualMinute() >= 55)
			Adblock.dragged = False
 		 EndIf
		EndIf

        If gfxListenabled=0 And MOUSEMANAGER.IsHit(1)
	    	If AdBlock.dragged = 0 And AdBlock.dragable = 1 And Adblock.State = 0
    	        If Adblock.senddate = game.daytoplan
					If functions.IsIn(MouseX(), MouseY(), AdBlock.pos.x, Adblock.pos.y, AdBlock.width, AdBlock.height-1)
						AdBlock.dragged = 1
						For Local OtherlocObject:TAdBlock = EachIn TAdBlock.List
							If OtherLocObject.dragged And OtherLocObject <> Adblock And OtherLocObject.owner = Game.playerID
								TPosition.SwitchPos(AdBlock.StartPos, OtherlocObject.StartPos)
  								OtherLocObject.dragged = 1
								If OtherLocObject.GetTimeOfBlock() < game.GetActualHour() And game.GetActualMinute() >= 55
									OtherLocObject.dragged = 0
								EndIf
							End If
						Next
						Adblock.RemoveBlock() 'just removes the contract from the plan, the adblock still exists
						AdBlock.GetPreviousContractCount()
					EndIf
				EndIf
			Else
            Local DoNotDrag:Int = 0
            If PPprogrammeList.enabled=0 And MOUSEMANAGER.IsHit(1)  And Adblock.State = 0
'			  Print ("X:"+Adblock.x+ " Y:"+Adblock.y+" time:"+Adblock.GetTimeOfBlock(Adblock.x,Adblock.y))' > game.GetActualHour())
              AdBlock.dragged = 0
              For Local DragAndDrop:TDragAndDrop = EachIn TAdBlock.DragAndDropList
                If DragAndDrop.Drop(MouseX(),MouseY(),"adblock") = 1
                  For Local OtherAdBlock:TAdBlock = EachIn TAdBlock.List
                   If OtherAdBlock.owner = Game.playerID Then
                   'is there a Adblock positioned at the desired place?
                      If MOUSEMANAGER.IsHit(1) And OtherAdBlock.dragable = 1 And OtherAdBlock.pos.x = DragAndDrop.pos.x
                        If OtherAdblock.senddate = game.daytoplan
                         If OtherAdBlock.pos.y = DragAndDrop.pos.y
                           If OtherAdBlock.State = 0
                             OtherAdBlock.dragged = 1
           	    	         otherAdblock.RemoveBlock()
          					 havetosort = 1
                           Else
                             DoNotDrag = 1
                           EndIf
             	         EndIf
             	        EndIf
                      EndIf
                    If havetosort
       				  OtherAdBlock.GetPreviousContractCount()
  	          		  AdBlock.GetPreviousContractCount()
                      Exit
                    EndIf
                   EndIf
                  Next
                  If DoNotDrag <> 1
						local oldPos:TPosition = TPosition.CreateFromPos(AdBlock.StartPos)
               		 AdBlock.startPos.SetPos(DragAndDrop.pos)
					 If Adblock.GetTimeOfBlock() < Game.GetActualHour() Or (Adblock.GetTimeOfBlock() = Game.GetActualHour() And Game.GetActualMinute() >= 55)
						adblock.dragged = True
						If AdBlock.startPos.isSame(oldPos) Then Adblock.dragged = False
						AdBlock.StartPos.setPos(oldPos)
						MOUSEMANAGER.resetKey(1)
					 Else
						AdBlock.StartPos.setPos(oldPos)
						Adblock.Pos.SetPos(DragAndDrop.pos)
			    		TDragAndDrop.SetDragAndDropTargetState(0,AdBlock.DragAndDropList, AdBlock.StartPos)
		    			TDragAndDrop.SetDragAndDropTargetState(1,AdBlock.DragAndDropList, AdBlock.pos)
						AdBlock.StartPos.SetPos(AdBlock.pos)
                     EndIf
					Exit 'exit loop-each-dragndrop, we've already found the right position
				  EndIf
                EndIf
              Next
				If AdBlock.IsAtStartPos()
					AdBlock.Pos.SetPos(AdBlock.StartPos)
	      		    AdBlock.dragged    			= 0
    	            AdBlock.contract.sendtime	= Adblock.GetTimeOfBlock()
        	        AdBlock.contract.senddate	= Game.daytoplan
            	    AdBlock.sendtime			= Adblock.GetTimeOfBlock()
                	AdBlock.senddate			= Game.daytoplan
	   	            Adblock.AddBlock()
					SortList(TAdBlock.List)
    		        AdBlock.GetPreviousContractCount()
				EndIf
            EndIf
          EndIf
         EndIf

        If AdBlock.dragged = 1
  		  	Adblock.State = 0
			TAdBlock.AdditionallyDragged = TAdBlock.AdditionallyDragged +1
			AdBlock.Pos.SetXY(MouseX() - AdBlock.width  /2 - TAdBlock.AdditionallyDragged *5,..
							  MouseY() - AdBlock.height /2 - TAdBlock.AdditionallyDragged *5)
        EndIf
        If AdBlock.dragged = 0
          If Adblock.StartPos.x = 0 And Adblock.StartPos.y = 0
          	AdBlock.dragged = 1
          	TAdBlock.AdditionallyDragged = TAdBlock.AdditionallyDragged +1
          Else
				AdBlock.Pos.SetPos(AdBlock.StartPos)
          EndIf
        EndIf
      EndIf
      If origowner = Adblock.owner ' or Adblock.owner = Game.playerID
     	'AdBlock.Draw()
      EndIf
      Next
        TAdBlock.AdditionallyDragged = 0
    End Function

  Method RemoveOverheadAdblocks:Int()
    sendtime = GetTimeOfBlock()
  	Local count:Int = 1
  	If Not List Then List = CreateList()
  	For Local AdBlock:TAdBlock= EachIn List
  	  If Adblock.owner = contract.owner And Adblock.contract.title = contract.title And adblock.contract.botched <> 1
  	    AdBlock.contract.spotnumber = count
  	    If count > contract.spotcount And Game.day <= Adblock.senddate
  	      'DebugLog "removing overheadadblock"
  	      'TAdBlock.List.Remove(Adblock)
		  Adblock.Link.Remove()
  	    Else
  	      count :+ 1
  	    EndIf
  	  EndIf
  	Next
  '	contract.spotnumber = count-1
  	Return count
  End Method

  'removes Adblocks which are supposed to be deleted for its contract being obsolete (expired)
  Function RemoveAdblocks:Int(Contract:TContract, BeginDay:Int=0)
  	If Not List Then List = CreateList()
  	For Local AdBlock:TAdBlock= EachIn List
  	  If Adblock.owner = contract.owner And Adblock.contract.title = contract.title And..
	     (adblock.contract.daysigned + adblock.contract.daystofinish < BeginDay)
        'TAdBlock.List.Remove(Adblock)
		Adblock.Link.Remove()
  	  EndIf
  	Next
  End Function

   Method ShowSheet:Int(x:Int,y:Int)
    contract.GetMinAudienceNumber(contract.minaudience)
 	gfx_datasheets_contract.render(x,y)
	'DrawImage gfx_datasheets_contract,x,y

	FontManager.baseFont.DrawBlock(contract.title 	       , x+10 , y+8  , 270, 70)  'prints title on moviesheet
 	FontManager.baseFont.DrawBlock(contract.description      , x+10 , y+30 , 270, 70) 'prints programmedescription on moviesheet
 	FontManager.baseFont.DrawBlock(GetLocale("AD_PROFIT")+": "       , x+10 , y+91 , 130, 16)
 	FontManager.baseFont.DrawBlock(functions.convertValue(String(contract.calculatedProfit), 2, 0) , x+10 , y+91 , 130, 16,2)
 	FontManager.baseFont.DrawBlock(GetLocale("AD_TOSEND")+": "    , x+150, y+91 , 127, 16)
 	FontManager.baseFont.DrawBlock((contract.spotcount - GetSuccessfullSentContractCount())+"/"+contract.spotcount , x+150, y+91 , 127, 16,2)
 	FontManager.baseFont.DrawBlock(GetLocale("AD_PENALTY")+": "       , x+10 , y+114, 130, 16)
 	FontManager.baseFont.DrawBlock(functions.convertValue(String(contract.calculatedPenalty), 2, 0), x+10 , y+114, 130, 16,2)
 	FontManager.baseFont.DrawBlock(GetLocale("AD_MIN_AUDIENCE")+": "    , x+150, y+114, 127, 16)
 	FontManager.baseFont.DrawBlock(functions.convertValue(String(contract.calculatedminaudience), 2, 0), x+150, y+114, 127, 16,2)
 	FontManager.baseFont.DrawBlock(GetLocale("AD_TARGETGROUP")+": "+TContract.GetTargetgroupName(contract.targetgroup)   , x+10 , y+137 , 270, 16)
 	If (contract.daystofinish-(Game.day - contract.daysigned)) = 0
 	  FontManager.baseFont.DrawBlock(GetLocale("AD_TIME")+": "+GetLocale("AD_TILL_TODAY") , x+86 , y+160 , 126, 16)
 	Else If (contract.daystofinish-(Game.day - contract.daysigned)) = 1
 	  FontManager.baseFont.DrawBlock(GetLocale("AD_TIME")+": "+GetLocale("AD_TILL_TOMORROW") , x+86 , y+160 , 126, 16)
 	Else
 	  FontManager.baseFont.DrawBlock(GetLocale("AD_TIME")+": "+Replace(GetLocale("AD_STILL_X_DAYS"),"%1", (contract.daystofinish-(Game.day - contract.daysigned))), x+86 , y+160 , 126, 16)
 	EndIf
 End Method

   Method GetPreviousContractCount:Int()
    sendtime = GetTimeOfBlock()
  	Local count:Int = 1
  	If Not List Then List = CreateList()
  	For Local AdBlock:TAdBlock= EachIn List
  	  If Adblock.owner = contract.owner And Adblock.contract.title = contract.title And adblock.contract.botched <> 1
  	    AdBlock.contract.spotnumber = count
  	    count :+ 1
  	  '  If count > contract.spotcount and Game.day > Game.daytoplan Then count = 1
  	  EndIf
  	Next
  '	contract.spotnumber = count-1
  	Return count
  End Method

   Method GetSuccessfullSentContractCount:Int()
    sendtime = GetTimeOfBlock()
  	Local count:Int = 0
  	If Not List Then List = CreateList()
  	For Local AdBlock:TAdBlock= EachIn List
  	  If Adblock.owner = contract.owner And Adblock.contract.title = contract.title And adblock.contract.botched = 3
  	    count :+ 1
  	  EndIf
  	Next
  	Return count
  End Method
    'remove from programmeplan
    Method RemoveBlock()
   	  Player[Game.playerID].ProgrammePlan.RemoveContract(Self.contract)
      If game.networkgame Then Network.SendPlanAdChange(game.playerID, Self, 0)
    End Method

    Method AddBlock()
      'Print "LOCAL: added adblock:"+Self.contract.title
'      Player[game.playerID].ProgrammePlan.RefreshProgrammePlan(game.playerID, Self.Programme.senddate)
      Player[Game.playerID].ProgrammePlan.AddContract(Self.contract)
      If game.networkgame Then Network.SendPlanAdChange(game.playerID, Self, 1)
    End Method

    Function GetBlockByContract:TAdBlock(contract:TContract)
	 For Local _AdBlock:TAdBlock = EachIn TAdBlock.List
		If contract.daysigned = _Adblock.contract.daysigned..
		   And contract.title = _Adblock.contract.title..
		   And contract.owner = _Adblock.contract.owner
		  Return _Adblock
		EndIf
	 Next
    End Function

	Function GetBlock:TAdBlock(id:Int)
	 For Local _AdBlock:TAdBlock = EachIn TAdBlock.List
	 	If _Adblock.ID = id Then Return _Adblock
	 Next
		return null
	End Function
End Type

Type TProgrammeBlock Extends TBlockGraphical
    Field id:Int = -1 {saveload = "normal"}
	Field State:Int = 0 {saveload = "normal"}
'    Field timeset:Int = -1 {saveload = "normal"}

    Field image:TGW_Sprites
    Field image_dragged:TGW_Sprites
    Field Programme:TProgramme
'    Field ParentProgramme:TProgramme
    Global LastUniqueID:Int =0
    Global DragAndDropList:TList

	Field sendHour:Int = -1					'which hour of the game (24h*day+dayHour) block is planned to be send?
'	Field senddate:Int = -1					'which day this block is planned to be send?
'	Field sendtime:Int = -1 				'which time this block is planned to be send?


  Function LoadAll(loadfile:TStream)
'    TProgrammeBlock.List.Clear()
    Local BeginPos:Int = Stream_SeekString("<PRB/>",loadfile)+1
    Local EndPos:Int = Stream_SeekString("</PRB>",loadfile)  -6
    Local strlen:Int = 0
    loadfile.Seek(BeginPos)

	TProgrammeBlock.lastUniqueID:Int        = ReadInt(loadfile)
    TProgrammeBlock.AdditionallyDragged:Int = ReadInt(loadfile)
'	Local FinishString:String = ""
	Repeat
      Local ProgrammeBlock:TProgrammeBlock = New TProgrammeBlock
 	  ProgrammeBlock.image = Assets.GetSprite("pp_programmeblock1")
 	  ProgrammeBlock.image_dragged = Assets.GetSprite("pp_programmeblock1_dragged")
	  ProgrammeBlock.id   = ReadInt(loadfile)
	  ProgrammeBlock.state    = ReadInt(loadfile)
	  ProgrammeBlock.dragable = ReadInt(loadfile)
	  ProgrammeBlock.dragged = ReadInt(loadfile)
	  ProgrammeBlock.StartPos.Load(Null)
	  ProgrammeBlock.height = ReadInt(loadfile)
	  ProgrammeBlock.width = ReadInt(loadfile)
	  ProgrammeBlock.Pos.Load(Null)
	  Local progID:Int = ReadInt(loadfile)
      Local ProgSendHour:Int = ReadInt(loadfile)
	  Local ParentprogID:Int = ReadInt(loadfile)
	  ProgrammeBlock.owner    = ReadInt(loadfile)
      If ProgID >= 0
        ProgrammeBlock.Programme 		  = Tprogramme.GetProgramme(ProgID) 'change owner?
        ProgrammeBlock.sendHour = ProgSendHour
	  EndIf
	  Player[ProgrammeBlock.owner].ProgrammePlan.ProgrammeBlocks.addLast(ProgrammeBlock)
	  ReadString(loadfile, 5)  'finishing string (eg. "|PRB|")
'	  Player[ProgrammeBlock.owner].ProgrammePlan.AddProgramme(ProgrammeBlock.Programme, 1)
	Until loadfile.Pos() >= EndPos 'Or FinishString <> "|PRB|"
	Print "loaded programmeblocklist"
  End Function

	Function SaveAll()
		'foreach player !
		rem
		LoadSaveFile.xmlBeginNode("ALLPROGRAMMEBLOCKS")
			LoadSaveFile.xmlWrite("LASTUNIQUEID",		TProgrammeBlock.LastUniqueID)
			LoadSaveFile.xmlWrite("ADDITIONALLYDRAGGED",TProgrammeBlock.AdditionallyDragged)
		    For Local ProgrammeBlock:TProgrammeBlock= EachIn TProgrammeBlock.List
				If ProgrammeBlock <> Null Then ProgrammeBlock.Save()
			Next
		LoadSaveFile.xmlCloseNode()
		endrem
	End Function

	Method Save()
		LoadSaveFile.xmlBeginNode("PROGRAMMEBLOCK")
			Local typ:TTypeId = TTypeId.ForObject(Self)
			For Local t:TField = EachIn typ.EnumFields()
				If t.MetaData("saveload") = "normal" Or t.MetaData("saveload") = "normalExt"
					LoadSaveFile.xmlWrite(Upper(t.name()), String(t.Get(Self)))
				EndIf
			Next
			If Self.Programme <> Null
				LoadSaveFile.xmlWrite("PROGRAMMEID", Self.Programme.id)
				LoadSavefile.xmlWrite("PROGRAMMESENDHOUR",	Self.sendhour)
			Else
				LoadSavefile.xmlWrite("PROGRAMMEID",		"-1")
				LoadSavefile.xmlWrite("PROGRAMMESENDDATE",	"-1")
				LoadSavefile.xmlWrite("PROGRAMMESENDTIME",	"-1")
			EndIf
	 	LoadSaveFile.xmlCloseNode()
	End Method

	Method SetStartConfig(x:Float, y:Float, owner:Int=0, state:Int=0)
 	  Self.image 		= Assets.GetSprite("pp_programmeblock1")
 	  Self.image_dragged= Assets.GetSprite("pp_programmeblock1_dragged")
	  Self.Pos			= TPosition.Create(x, y)
	  Self.StartPos		= TPosition.Create(x, y)
 	  Self.owner 		= owner
 	  Self.State 		= state
	  Self.id 			= self.lastUniqueID
	  self.lastUniqueID:+1
 	  Self.dragable 	= 1
 	  Self.width 		= Self.image.w
 	  Self.Height 		= Self.image.h
	End Method


    'creates a programmeblock which is already dragged (used by movie/series-selection)
    'erstellt einen gedraggten Programmblock (genutzt von der Film- und Serienauswahl)
	Function CreateDragged:TProgrammeBlock(movie:TProgramme, owner:Int =-1)
		If owner < 0 Then owner = game.playerID
		Local ProgrammeBlock:TProgrammeBlock=New TProgrammeBlock
		ProgrammeBlock.SetStartConfig(MouseX(),MouseY(),owner, 0)
		TProgrammeBlock.LastUniqueID :+1
		ProgrammeBlock.dragged = 1
		ProgrammeBlock.Programme= movie
		ProgrammeBlock.sendHour	= TPlayerProgrammePlan.getPlanHour(ProgrammeBlock.GetHourOfBlock(1, ProgrammeBlock.StartPos),Game.daytoplan)

		Player[owner].ProgrammePlan.AdditionallyDraggedProgrammeBlocks :+ 1
		Player[owner].ProgrammePlan.ProgrammeBlocks.addLast(ProgrammeBlock)

 	  Return ProgrammeBlock
	End Function

	Function Create:TProgrammeBlock(x:Int=0, y:Int=0, serie:Int=0, owner:Int=0, programmepos:Int=-1)
		Local ProgrammeBlock:TProgrammeBlock=New TProgrammeBlock
 	  ProgrammeBlock.SetStartConfig(x,y,owner, Rnd(0,3))
      If Programmepos <= -1
		ProgrammeBlock.Programme = Player[owner].ProgrammeCollection.GetLocalRandomProgramme(serie)
 	  Else
 	    SortList(Player[owner].ProgrammeCollection.MovieList)
 	    ProgrammeBlock.Programme = TProgramme(Player[owner].ProgrammeCollection.MovieList.ValueAtIndex(programmepos))
 	  EndIf

		ProgrammeBlock.sendHour	= TPlayerProgrammePlan.getPlanHour(ProgrammeBlock.GetHourOfBlock(1, ProgrammeBlock.StartPos),Game.daytoplan)

		Player[owner].ProgrammePlan.ProgrammeBlocks.addLast(ProgrammeBlock)

 	  'Print "Player "+owner+" -Create block: added:"+programmeblock.Programme.title
 	  Return ProgrammeBlock
	End Function

	Method SetDragable(_dragable:Int = 1)
		dragable = _dragable
	End Method

    Method Compare:Int(otherObject:Object)
		Local s:TProgrammeBlock = TProgrammeBlock(otherObject)
		If Not s Then Return 1                  ' Objekt nicht gefunden, an das Ende der Liste setzen
		return not s.dragged
    End Method

    Method DraggingAllowed:int()
    	return (dragable And self.GetState() = 0 And owner=Game.playerID)
    End Method

    Method DrawBlockPart(x:Int,y:Int,kind:Int, variant:string="")
    	If kind=1
			Assets.GetSprite("pp_programmeblock2"+variant).DrawClipped(x, y, x, y, -1, 30)
    	else
			Assets.GetSprite("pp_programmeblock2"+variant).DrawClipped(x, y - 30, x, y, -1, 15)
    	    If kind=2
				Assets.GetSprite("pp_programmeblock2"+variant).DrawClipped(x, y - 30 + 15, x, y + 15, -1, 15)
    	    Else
				Assets.GetSprite("pp_programmeblock2"+variant).DrawClipped(x, y - 30, x, y + 15, -1, -1)
    	    EndIf
	    EndIf
    End Method

	Method GetState:Int()
		State = 1
		If Game.day > Game.daytoplan Then State = 4
		If Game.day < Game.daytoplan Then State = 0
		If Game.day = Game.daytoplan
			'xx:05
			local moviesStartTime:int	= Int(Floor((Game.minutesOfDayGone-5) / 60))
			'xx:55
			local moviesEndTime:int		= Int(Floor((Game.minutesOfDayGone+5) / 60)) 'with ad
			Local startTime:Int			= self.GetHourOfBlock(1, self.StartPos)
			Local endTime:Int			= self.GetHourOfBlock(self.programme.blocks, self.StartPos)
			'running or runned (1 or 2)
			If startTime <= moviesStartTime then State = 1 + (endTime >= moviesEndTime)
			'not run - normal
			if startTime > moviesStartTime OR self.sendHour < 0 then State = 0
		EndIf
		return State
	End Method

	'draw the programmeblock inclusive text
    'zeichnet den Programmblock inklusive Text
	Method Draw()
		'Draw dragged programmeblockgraphic
		If self.dragged = 1 Or functions.DoMeet(self.sendHour, self.sendHour + self.programme.blocks, Game.daytoplan*24,Game.daytoplan*24+24)  'out of gameplanner
			GetState()
			If dragged Then state = 0
			If State = 0 Then SetColor 255,255,255;dragable=1  'normal
			If State = 1 Then SetColor 200,255,200;dragable=0  'runned
			If State = 2 Then SetColor 250,230,120;dragable=0  'running
			If State = 4 Then SetColor 255,255,255;dragable=0  'old day

			local variant:string = ""
			local drawTitle:int = 1
			if dragged = 1 and state=0 then variant = "_dragged"

			If programme.blocks = 1
				Assets.GetSprite("pp_programmeblock1"+variant).Draw(pos.x, pos.y)
			Else
				For Local i:Int = 1 To self.programme.blocks
					local _type:int = 1
					if i > 1 and i < self.programme.blocks then _type = 2
					if i = self.programme.blocks then _type = 3
					if self.dragged
						'draw on manual position
						self.DrawBlockPart(pos.x,pos.y + (i-1)*30,_type)
					else
						'draw on "planner spot" position
						local _pos:TPosition = Self.getSlotXY(self.sendhour+i-1)

						if self.sendhour+i-1 >= game.daytoplan*24 AND self.sendhour+i-1 < game.daytoplan*24+24
							self.DrawBlockPart(_pos.x,_pos.y ,_type)
							if i = 1 then pos = _pos
						else
							if i=1 then drawTitle = 0
						endif
					endif
				Next
			EndIf
			if drawTitle then self.DrawBlockText(TColor.Create(50,50,50), self.pos)
		EndIf 'daytoplan switch
    End Method

    Method DrawBlockText(color:TColor = null, _pos:TPosition)
		SetColor 0,0,0

		local maxWidth:int = self.image.w - 5
		local title:string = self.programme.title
		if not self.programme.isMovie
			title = self.programme.parent.title + " (" + self.programme.episodeNumber + "/" + self.programme.parent.episodeCount + ")"
		endif

		While FontManager.baseFont.getWidth(title) > maxWidth AND title.length > 4
			title = title[..title.length-3]+".."
		Wend

		FontManager.baseFont.DrawBlock(title, _pos.x + 5, _pos.y +2, self.image.w - 10, 18, 0, 0, 0, 0, True)
		if color <> null then color.set()
		local useFont:TBitmapFont = FontManager.GetFont("Default", 11, ITALICFONT)
		If programme.parent <> Null
			useFont.Draw(self.Programme.getGenre()+"-Serie",_pos.x+5,_pos.y+18)
			useFont.Draw("Teil: " + self.Programme.episodeNumber + "/" + self.programme.parent.episodecount, _pos.x + 138, _pos.y + 18)
		Else
			useFont.Draw(self.Programme.getGenre(),_pos.x+5,_pos.y+18)
			If self.programme.fsk18 <> 0 Then useFont.Draw("FSK 18!",_pos.x+138,_pos.y+18)
		EndIf
		SetColor 255,255,255
	End Method

	Method DrawShades()
		'draw a shade of the programmeblock on its original position but not when just created and so dragged from its creation on
		 If (self.StartPos.x = 394 Or self.StartPos.x = 67) And (Abs(self.pos.x - self.StartPos.x) > 0 Or Abs(self.pos.y - self.StartPos.y) >0)
			SetAlpha 0.4
			If self.programme.blocks = 1
				self.image.Draw(self.StartPos.x, self.StartPos.y)
			Else
				For Local i:Int = 1 To self.programme.blocks
					local _pos:TPosition = Self.getBlockSlotXY(i, self.startPos)
					local _type:int = 1
					if i > 1 and i < self.programme.blocks then _type = 2
					if i = self.programme.blocks then _type = 3
					self.DrawBlockPart(_pos.x,_pos.y,_type)
				Next
			EndIf
			self.DrawBlockText( TColor.Create(80,80,80), self.startPos )

			SetAlpha 1.0
		EndIf
	End Method

    Method DeleteBlock()
		Print "delete programme:"+Self.Programme.title
		'remove self from block list
		Player[Game.playerID].ProgrammePlan.ProgrammeBlocks.remove(self)
		Player[Game.playerID].ProgrammePlan.RemoveProgramme(Self.Programme)
    End Method

rem
	Method GetSlot:int(blockNumber:int=1)
		if self.sendHour < 0 then return -1
		return ((self.sendHour + blockNumber) mod 24)
	End Method
endrem

	'give total hour - returns x of planner-slot
	Method GetSlotX:Int(time:Int)
		return GetSlotXY(time).x
	End Method

	'give total hour - returns y of planner-slot
	Method GetSlotY:Int(time:int)
		return GetSlotXY(time).y
	End Method

	'give total hour - returns position of planner-slot
	Method GetSlotXY:TPosition(totalHours:Int)
		totalHours = totalHours mod 24
		local top:int = 17
		if floor(totalHours/12) mod 2 = 1 '(12-23, + next day 12-23 and so on)
			return TPosition.Create(394, top + (totalHours - 12)*30)
		else
			return TPosition.Create(67, top + totalHours*30)
		endif
	End Method

	'returns the slot coordinates of a position on the plan
	'returns for current day not total (eg. 0-23)
	Method GetBlockSlotXY:TPosition(blockNumber:int, _pos:TPosition = null)
		return self.GetSlotXY( self.GetHourOfBlock(blockNumber, _pos) )
	End Method

	'returns the hour of a position on the plan
	'returns for current day not total (eg. 0-23)
	Method GetHourOfBlock:int(blockNumber:int, _pos:TPosition= null)
		if _pos = null then _pos = self.pos
		'0-11 links, 12-23 rechts
		local top:int = 17
		return (_pos.y - top) / 30 + 12*(_pos.x = 394)   +  (blockNumber-1)
	End Method

    'remove from programmeplan
    Method Drag()
		if self.dragged <> 1
			self.dragged	= 1
			self.sendHour	= -1

			'reset a DnD-Zone when a block is dragged -> set is as unused
			For Local i:Int = 1 To programme.blocks
				local _pos:TPosition = self.GetBlockSlotXY(i, StartPos)
				TDragAndDrop.SetDragAndDropTargetState(0,DragAndDropList, _pos)
			Next
			'emit event ?
			If game.networkgame Then Network.SendPlanProgrammeChange(game.playerID, Self, 0)
		endif
    End Method

	'add to plan again
    Method Drop()
		if self.dragged <> 0
			self.dragged = 0
			Pos.SetPos(StartPos)
			self.sendHour = TPlayerProgrammePlan.getPlanHour(self.getHourOfBlock(1, self.pos), game.daytoplan)

			'emit event ?
			If game.networkgame Then Network.SendPlanProgrammeChange(game.playerID, Self, 1)
		endif
    End Method
End Type

Type TNewsBlock Extends TBlockGraphical
	Field State:Int 		= 0 	{saveload = "normal"}
    Field sendslot:Int 		= -1 	{saveload = "normal"} 'which day this news is planned to be send?
    Field publishdelay:Int 	= 0		{saveload = "normal"} 'value added to publishtime when compared with Game.minutesOfDayGone to delay the "usabilty" of the block
    Field publishtime:Int 	= 0		{saveload = "normal"} '
    Field paid:Byte 		= 0 	{saveload = "normal"}
    Field news:TNews
	Field id:Int	 		= 0 	{saveload = "normal"}
    Global LastUniqueID:Int 		= 0
    Global DragAndDropList:TList

    Global LeftListPosition:Int		= 0
    Global LeftListPositionMax:Int	= 4


	Function LoadAll(loadfile:TStream)
'		TNewsBlock.List.Clear()
		'Print "cleared newsblocklist:"+TNewsBlock.List.Count()
		Local BeginPos:Int = Stream_SeekString("<NEWSB/>",loadfile)+1
		Local EndPos:Int = Stream_SeekString("</NEWSB>",loadfile)  -8
		Local strlen:Int = 0
		loadfile.Seek(BeginPos)

		TNewsBlock.lastUniqueID:Int        = ReadInt(loadfile)
		TNewsBlock.AdditionallyDragged:Int = ReadInt(loadfile)
		TNewsBlock.LeftListPosition:Int    = ReadInt(loadfile)
		TNewsBlock.LeftListPositionMax:Int = ReadInt(loadfile)
		Local NewsBlockCount:Int = ReadInt(loadfile)
		If NewsBlockCount > 0
			Repeat
				Local NewsBlock:TNewsBlock= New TNewsBlock
				NewsBlock.State      	= ReadInt(loadfile)
				NewsBlock.dragable   	= ReadByte(loadfile)
				NewsBlock.dragged    	= ReadByte(loadfile)
				NewsBlock.StartPos.Load(Null)
				NewsBlock.sendslot   	= ReadInt(loadfile)
				NewsBlock.publishdelay= ReadInt(loadfile)
				NewsBlock.publishtime	= ReadInt(loadfile)
				NewsBlock.paid 		= ReadByte(loadfile)
				NewsBlock.Pos.Load(Null)
				NewsBlock.owner		= ReadInt(loadfile)
				NewsBlock.id	= ReadInt(loadfile)
				Local NewsID:Int		= ReadInt(loadfile)
				If newsID >= 0 Then Newsblock.news = TNews.Load(Null) 'loadfile)

				NewsBlock.imageBaseName = "gfx_news_sheet"
				NewsBlock.width 		= Assets.GetSprite("gfx_news_sheet0").w
				NewsBlock.Height		= Assets.GetSprite("gfx_news_sheet0").h

				'TNewsBlock.List.AddLast(NewsBlock)
				ReadString(loadfile,5) 'finishing string (eg. "|PRB|")
				Player[NewsBlock.owner].ProgrammePlan.AddNewsBlock(NewsBlock)
				Print "added '" + NewsBlock.news.title + "' to programmeplan for:"+newsBlock.owner
			Until loadfile.Pos() >= EndPos
		EndIf
		Print "loaded newsblocklist"
	End Function

	Function SaveAll()
		LoadSaveFile.xmlBeginNode("ALLNEWSBLOCKS")
			LoadSaveFile.xmlWrite("LASTUNIQUEID",		TNewsBlock.LastUniqueID)
			LoadSaveFile.xmlWrite("ADDITIONALLYDRAGGED",TNewsBlock.AdditionallyDragged)
			LoadSaveFile.xmlWrite("LEFTLISTPOSITION",	TNewsBlock.LeftListPosition)
			LoadSaveFile.xmlWrite("LEFTLISTPOSITIONMAX",TNewsBlock.LeftListPositionMax)
			'SaveFile.WriteInt(TNewsBlock.List.Count())
			for local i:int = 1 to 4
				For Local NewsBlock:TNewsBlock= EachIn Player[i].ProgrammePlan.NewsBlocks
					If NewsBlock <> Null Then NewsBlock.Save()
				Next
			Next
		LoadSaveFile.xmlCloseNode()
	End Function

	Method Save()
		LoadSaveFile.xmlBeginNode("NEWSBLOCK")
			Local typ:TTypeId = TTypeId.ForObject(Self)
			For Local t:TField = EachIn typ.EnumFields()
				If t.MetaData("saveload") = "normal" Or t.MetaData("saveload") = "normalExt"
					LoadSaveFile.xmlWrite(Upper(t.name()), String(t.Get(Self)))
				EndIf
			Next
			If Self.news <> Null
				LoadSaveFile.xmlWrite("NEWSID",		Self.news.id)
				Self.news.Save()
			Else
				LoadSaveFile.xmlWrite("NEWSID",		"-1")
			EndIf
		LoadSaveFile.xmlCloseNode()
	End Method

	Function Create:TNewsBlock(text:String="unknown", x:Int=0, y:Int=0, owner:Int=1, publishdelay:Int=0, usenews:TNews=Null)
	  Local LocObject:TNewsBlock=New TNewsBlock
	  LocObject.Pos		= TPosition.Create(x, y)
	  LocObject.StartPos= TPosition.Create(x, y)
 	  LocObject.owner = owner
 	  LocObject.State = 0
 	  locobject.publishdelay = publishdelay
 	  locobject.publishtime = Game.timeSinceBegin
 	  'hier noch als variablen uebernehmen
 	  LocObject.dragable = 1
 	  LocObject.sendslot = -1
 	  locObject.id = TNewsBlock.LastUniqueID
 	  TNewsBlock.LastUniqueID :+1

	  If usenews = Null Then usenews = TNews.GetRandomNews()

 	  LocObject.news = usenews

		Locobject.imageBaseName = "gfx_news_sheet"
		Locobject.imageBaseName = "gfx_news_sheet" '_dragged
		LocObject.width 		= Assets.GetSprite(Locobject.imageBaseName+"0").w
		LocObject.Height		= Assets.GetSprite(Locobject.imageBaseName+"0").h

		Player[owner].ProgrammePlan.AddNewsBlock(LocObject)
		Return LocObject
	End Function

    Method Pay()
        Player[owner].finances[TFinancials.GetDayArray(Game.day)].PayNews(news.ComputePrice())
    End Method

	Function IncLeftListPosition:Int(amount:Int=1)
      If TNewsBlock.LeftListPositionMax-TNewsBlock.LeftListPosition > 4 Then TNewsBlock.LeftListPosition:+amount
	End Function

	Function DecLeftListPosition:Int(amount:Int=1)
		TNewsBlock.LeftListPosition = Max(0, TNewsBlock.LeftListPosition -amount)
	End Function

	Method SetDragable(_dragable:Int = 1)
		dragable = _dragable
	End Method


    function Sort:Int(o1:object, o2:Object)
		Local n1:TNewsBlock = TNewsBlock(o1)
		Local n2:TNewsBlock = TNewsBlock(o2)
		If Not n2 Then Return 1                  ' Objekt nicht gefunden, an das Ende der Liste setzen
		return (not n2.dragged) * (n2.news.happenedday*10000+n2.news.happenedhour*100+n2.news.happenedminute) - (not n1.dragged) * (n1.news.happenedday*10000+n1.news.happenedhour*100+n1.news.happenedminute)
    End Function

    Method GetSlotOfBlock:Int()
    	If pos.x = 445 And dragged = 0 Then Return Int((StartPos.y - 19) / 87)
    	Return -1
    End Method

    'draw the Block inclusive text
	Method Draw()
		State = 0
		SetColor 255,255,255
		dragable=1
		local variant:string = ""
		If dragged = 1 And State = 0
			If self.AdditionallyDragged > 0 Then SetAlpha 1- 1/self.AdditionallyDragged * 0.25
			'variant = "_dragged"
		EndIf
		Assets.GetSprite(self.imageBaseName+news.genre+variant).Draw(Pos.x, Pos.y)


		'draw graphic
		If paid Then FontManager.GetFont("Default", 9).drawBlock("€ OK", pos.x + 1, pos.y + 65, 14, 25, 1, 50, 50, 50)
		FontManager.baseFontBold.drawBlock(news.title, pos.x + 15, pos.y + 3, 290, 15 + 8, 0, 20, 20, 20)
		FontManager.baseFont.drawBlock(news.description, pos.x + 15, pos.y + 18, 300, 45 + 8, 0, 100, 100, 100)
		SetAlpha 0.3
		FontManager.GetFont("Default", 9).drawBlock(news.GetGenre(news.Genre), pos.x + 15, pos.y + 72, 120, 15, 0, 0, 0, 0)
		SetAlpha 1.0
		FontManager.GetFont("Default", 12).drawBlock(news.ComputePrice() + ",-", pos.x + 220, pos.y + 70, 90, 15, 2, 0, 0, 0)
		If Game.day - news.happenedday = 0 Then FontManager.baseFont.drawBlock("Heute " + Game.GetFormattedExternTime(news.happenedhour, news.happenedminute) + " Uhr", pos.x + 90, pos.y + 72, 140, 15, 2, 0, 0, 0)
		If Game.day - news.happenedday = 1 Then FontManager.baseFont.drawBlock("(Alt) Gestern " + Game.GetFormattedExternTime(news.happenedhour, news.happenedminute) + " Uhr", pos.x + 90, pos.y + 72, 140, 15, 2, 0, 0, 0)
		If Game.day - news.happenedday = 2 Then FontManager.baseFont.drawBlock("(Alt) Vorgestern " + Game.GetFormattedExternTime(news.happenedhour, news.happenedminute) + " Uhr", pos.x + 90, pos.y + 72, 140, 15, 2, 0, 0, 0)
		SetColor 255, 255, 255
		SetAlpha 1.0
	End Method

End Type

'Contracts used in AdAgency
Type TContractBlocks Extends TBlockGraphical
  Field contract:TContract
  Field slot:Int = 0 {saveload = "normal"}
  Field Link:TLink
  Global DragAndDropList:TList = CreateList()
  Global List:TList = CreateList()
  Global AdditionallyDragged:Int =0

  Function LoadAll(loadfile:TStream)
    TContractBlocks.List.Clear()
	Print "cleared contractblocklist:"+TContractBlocks.List.Count()
    Local BeginPos:Int = Stream_SeekString("<CONTRACTB/>",loadfile)+1
    Local EndPos:Int = Stream_SeekString("</CONTRACTB>",loadfile)  -12
    'Local strlen:Int = 0
    loadfile.Seek(BeginPos)
    TContractBlocks.AdditionallyDragged:Int = ReadInt(loadfile)
	Local ContractBlockCount:Int = ReadInt(loadfile)
	If ContractBlockCount > 0
	Repeat
      Local ContractBlock:TContractBlocks= New TContractBlocks
	  ContractBlock.Pos.Load(Null)
	  ContractBlock.OrigPos.Load(Null)
	  Local ContractID:Int  = ReadInt(loadfile)
	  If ContractID >= 0
	    ContractBlock.contract = TContract.GetContract(ContractID)
		Local targetgroup:Int = ContractBlock.contract.targetgroup
		If targetgroup > 9 Or targetgroup <0 Then targetgroup = 0
		ContractBlock.imageBaseName	= "gfx_contracts_"+targetgroup
 	  	ContractBlock.width		= Assets.getSprite(ContractBlock.imageBaseName).w
 	  	ContractBlock.Height	= Assets.getSprite(ContractBlock.imageBaseName).h
	  EndIf
	  ContractBlock.dragable= ReadInt(loadfile)
	  ContractBlock.dragged = ReadInt(loadfile)
	  ContractBlock.slot	= ReadInt(loadfile)
		ContractBlock.StartPos.Load(Null)
	  ContractBlock.owner   = ReadInt(loadfile)
	  ContractBlock.Link = TContractBlocks.List.AddLast(ContractBlock)
	  ReadString(loadfile,5) 'finishing string (eg. "|PRB|")
	Until loadfile.Pos() >= EndPos
	EndIf
	Print "loaded contractblocklist"
  End Function

	Function SaveAll()
		Local ContractCount:Int = 0
		LoadSaveFile.xmlBeginNode("ALLCONTRACTBLOCKS")
			LoadSaveFile.xmlWRITE("ADDITIONALLYDRAGGED"		, TContractBlocks.AdditionallyDragged)
			For Local ContractBlock:TContractBlocks= EachIn TContractBlocks.List
				If ContractBlock <> Null Then If ContractBlock.owner <= 0 Then ContractCount:+1
		    Next
			LoadSaveFile.xmlWRITE("CONTRACTCOUNT"				, ContractCount)
			For Local ContractBlock:TContractBlocks= EachIn TContractBlocks.List
				If ContractBlock <> Null Then ContractBlock.Save()
			Next
		LoadSaveFile.xmlCloseNode()
	End Function

	Method Save()
		LoadSaveFile.xmlBeginNode("CONTRACTBLOCK")
			Local typ:TTypeId = TTypeId.ForObject(Self)
			For Local t:TField = EachIn typ.EnumFields()
				If t.MetaData("saveload") = "normal" Or t.MetaData("saveload") = "normalExt" Or t.MetaData("saveload") = "normalExtB"
					LoadSaveFile.xmlWrite(Upper(t.name()), String(t.Get(Self)))
				EndIf
			Next
			If Self.contract <> Null
				LoadSaveFile.xmlWrite("CONTRACTID",		Self.contract.id)
			Else
				LoadSaveFile.xmlWrite("CONTRACTID",		"-1")
			EndIf
		LoadSaveFile.xmlCloseNode()
	End Method

  Function ContractsToPlayer:Int(playerID:Int)
   SortList(TContractBlocks.List)
   	For Local locObject:TContractBlocks = EachIn TContractBlocks.List
     If locobject.pos.x > 520 And locobject.owner <= 0
       locobject.owner = playerID
       If game.networkgame
	     Local ContractArray:TContract[1]
		 ContractArray[0] = locobject.contract
         If network.IsConnected Then Network.SendContract(game.playerID, ContractArray)
		 ContractArray = Null
       Else
         Player[playerID].ProgrammeCollection.AddContract(locobject.contract,playerID)
       EndIf
      Local x:Int=0
      Local y:Int = 0

	  x = 285 + locObject.slot * Assets.getSprite(locObject.imageBaseName).w
      y = 300 - 10 - Assets.getSprite(locObject.imageBaseName).h - locobject.slot * 7
	  LocObject.Pos.SetXY(x, y)
	  LocObject.OrigPos.SetXY(x, y)
	  LocObject.StartPos.SetXY(x, y)
 	  LocObject.dragable = 1
 	  locobject.contract = TContract.GetRandomContract()
	  If locobject.contract <> Null
        Local targetgroup:Int = Locobject.contract.targetgroup
        If targetgroup > 9 Or targetgroup <0 Then targetgroup = 0
			Locobject.imageBaseName = "gfx_contracts_"+targetgroup
	  EndIf
		locobject.owner = 0
     EndIf
    Next
  End Function

  Function RemoveContractFromSuitcase(contract:TContract)
	If contract <> Null
	  For Local ContractBlock:TContractBlocks =EachIn TContractBlocks.List
	    If ContractBlock.contract.id = contract.id
		  Print "removing contractblock (success)"
		  ContractBlock.Link.Remove()
		EndIf
	  Next
	End If
  End Function

  'if owner = 0 then its a block of the adagency, otherwise it's one of the player'
  Function Create:TContractBlocks(contract:TContract, slot:Int=0, owner:Int=0)
	  Local LocObject:TContractBlocks=New TContractBlocks
      Local x:Int=0
      Local y:Int=0
      Local targetgroup:Int = contract.targetgroup
      If targetgroup > 9 Or targetgroup <0 Then targetgroup = 0
		locObject.imageBaseName	= "gfx_contracts_"+targetgroup
 	  	locObject.width		= Assets.getSprite(locObject.imageBaseName).w
 	  	locObject.Height	= Assets.getSprite(locObject.imageBaseName).h

	  x = 285 + slot * LocObject.width
      y = 300 - 10 - LocObject.height - slot * 7
	  LocObject.Pos			= TPosition.Create(x, y)
	  LocObject.OrigPos		= TPosition.Create(x, y)
	  LocObject.StartPos	= TPosition.Create(x, y)
 	  LocObject.slot = slot
 	  locObject.owner = owner
 	  LocObject.dragable = 1
 	  LocObject.contract = contract
 	  If Not List Then List = CreateList()
 	  LocObject.Link = List.AddLast(LocObject)
 	  SortList List

If owner = 0
      Local DragAndDrop:TDragAndDrop = New TDragAndDrop
 	    DragAndDrop.slot = slot + 200
 	    DragAndDrop.pos.SetXY(x,y)
 	    DragAndDrop.used = 1
 	    DragAndDrop.w = LocObject.width
 	    DragAndDrop.h = LocObject.height
        TContractBlocks.DragAndDropList.AddLast(DragAndDrop)
Else
      LocObject.dragable = 0
EndIf
 	  Return LocObject
	End Function

	Method SetDragable(_dragable:Int = 1)
		dragable = _dragable
	End Method

    Method Compare:Int(otherObject:Object)
       Local s:TContractBlocks = TContractBlocks(otherObject)
       If Not s Then Return 1                  ' Objekt nicht gefunden, an das Ende der Liste setzen
        Return (dragged * 100)-(s.dragged * 100)
    End Method


    'draw the Block inclusive text
    'zeichnet den Block inklusive Text
    Method Draw()
      SetColor 255,255,255  'normal

      If dragged = 1
    	If TContractBlocks.AdditionallyDragged > 0 Then SetAlpha 1- 1/TContractBlocks.AdditionallyDragged * 0.25
		Assets.GetSprite(self.imageBaseName+"_dragged").Draw(Pos.x + 6, Pos.y)
      Else
        If Pos.x > 520
			If dragable = 0 Then SetColor 200,200,200
			Assets.GetSprite(self.imageBaseName+"_dragged").Draw(Pos.x, Pos.y)
            If dragable = 0 Then SetColor 255,255,255
        Else
			Assets.GetSprite(self.imageBaseName).Draw(Pos.x, Pos.y)
        EndIf
      EndIf
      SetAlpha 1
    End Method

	Function DrawAll(DraggingAllowed:Byte)
      Local localslot:Int = 0 'slot in suitcase

      SortList TContractBlocks.List
      For Local locObject:TContractBlocks = EachIn TContractBlocks.List
	   If locObject.contract <> Null
     	If locobject.owner = Game.playerID
     	  locobject.Pos.SetXY(550 + LocObject.image.w * localslot, 87)
		  locobject.StartPos.SetPos(locobject.Pos)
     	  locobject.dragable = 0
		  locobject.slot = localslot
     	  localslot:+1
     	End If
        If locobject.owner <= 0 Or locobject.owner = Game.playerID
     	  locObject.Draw()
        EndIf
	   EndIf 'ungleich null
      Next
  End Function

    Function UpdateAll(DraggingAllowed:Byte)
'      Local havetosort:Byte = 0
      Local number:Int = 0
      Local localslot:Int = 0 'slot in suitcase

      SortList TContractBlocks.List
      For Local locObject:TContractBlocks = EachIn TContractBlocks.List
	   If locObject.contract <> Null
     	If locobject.owner = Game.playerID
     	  locobject.Pos.SetXY(550 + LocObject.image.w * localslot, 87)
		  locobject.StartPos.SetPos(locobject.Pos)
     	  locobject.dragable = 0
		  locobject.slot = localslot
     	  localslot:+1
     	End If
      If DraggingAllowed And locobject.owner <= 0
        number :+ 1
        If MOUSEMANAGER.IsHit(2) And locObject.dragged = 1
			locObject.Pos.SetPos(locObject.StartPos)
          MOUSEMANAGER.resetKey(2)
        EndIf

        If MOUSEMANAGER.IsHit(1)
          If locObject.dragged = 0 And locObject.dragable = 1
            If functions.IsIn(MouseX(), MouseY(), locObject.Pos.x, locObject.Pos.y, locObject.width-1, locObject.height)
              locObject.dragged = 1
      		  For Local OtherlocObject:TContractBlocks = EachIn TContractBlocks.List
			    If OtherLocObject.dragged And OtherLocObject <> locObject
					TPosition.SwitchPos(locObject.StartPos, OtherLocObject.StartPos)
					OtherLocObject.dragged = 0
			    End If
			  Next
              TDragAndDrop.SetDragAndDropTargetState(0,locObject.DragAndDropList, locObject.StartPos)
			  MouseManager.resetKey(1)
            EndIf
          Else
            'Local DoNotDrag:Int = 0
            Local realDNDfound:Int = 0
              locObject.dragged = 0
              realDNDfound = 0
              For Local DragAndDrop:TDragAndDrop = EachIn TContractBlocks.DragAndDropList
                If DragAndDrop.CanDrop(MouseX(), MouseY()) = 1 And (DragAndDrop.pos.x < 550 Or DragAndDrop.pos.x > 550 + locobject.image.w * (localslot - 1))
                  For Local OtherlocObject:TContractBlocks= EachIn TContractBlocks.List
                   If DraggingAllowed And otherlocobject.owner <= 0
                     'is there a NewsBlock positioned at the desired place?
                      If MOUSEMANAGER.IsHit(1) And OtherlocObject.dragable = 1 And OtherlocObject.Pos.isSame(DragAndDrop.pos)
                         OtherlocObject.dragged = 1
                         TDragAndDrop.SetDragAndDropTargetState(0,OtherlocObject.DragAndDropList, OtherlocObject.StartPos)
           	         EndIf
                   EndIf
                  Next
					LocObject.Pos.SetPos(DragAndDrop.pos)
					TDragAndDrop.SetDragAndDropTargetState(1,locObject.DragAndDropList, locObject.StartPos)
					LocObject.StartPos.SetPos(LocObject.Pos)
                    realDNDfound =1
                    Exit 'exit loop-each-dragndrop, we've already found the right position
                EndIf
              Next
              'suitcase as dndzone
              If Not realDNDfound And functions.IsIn(MouseX(),MouseY(),540,70,190,100)
              	For Local DragAndDrop:TDragAndDrop = EachIn TContractBlocks.DragAndDropList
              		If functions.IsIn(DragAndDrop.pos.x, DragAndDrop.pos.y, 540,70,190,100)
              		  If DragAndDrop.pos.x >= 540 + LocObject.image.w * (localslot)
              		  If DragAndDrop.used = 0 'and DragAndDrop.slot > (localslot) Then
              		    DragAndDrop.used =1
						LocObject.Pos.SetPos(DragAndDrop.pos)
              			TDragAndDrop.SetDragAndDropTargetState(1,locObject.DragAndDropList, locObject.StartPos)
                        'DebugLog "suitcase-drop "+draganddrop.rectx
						LocObject.StartPos.SetPos(LocObject.Pos)
                        Exit 'exit loop-each-dragndrop, we've already found the right position
              		  End If
              		  EndIf
                	End If
              	Next
              End If
              'no drop-area under Adblock (otherwise this part is not executed - "exit"), so reset position
			  If LocObject.IsAtStartPos()
      		    locObject.dragged = 0
				LocObject.Pos.SetPos(LocObject.StartPos)
  				SortList TContractBlocks.List
              EndIf
            EndIf
         EndIf

        If locObject.dragged = 1
          TContractBlocks.AdditionallyDragged :+1
		  LocObject.Pos.SetXY(MouseX() - locObject.width /2 -  TContractBlocks.AdditionallyDragged *5,..
							  MouseY() - locObject.height /2 - TContractBlocks.AdditionallyDragged *5)
		Else
			LocObject.Pos.SetPos(LocObject.StartPos)
        EndIf
      EndIf
	  EndIf 'ungleich null
      Next
        TContractBlocks.AdditionallyDragged = 0
  End Function

End Type


Type TSuitcaseProgrammeBlocks Extends TBlockGraphical
	Field Programme:TProgramme
	field id:int = 0
	global LastID:int = 0

	Method getNewID()
		self.id = self.LastID
		self.LastID:+1
	EndMethod

    'draw the Block inclusive text
    'zeichnet den Block inklusive Text
    Method Draw(additionalDragged:int = 0)
      SetColor 255,255,255  'normal

      If dragged = 1
    	If additionalDragged > 0 Then SetAlpha 1- 1/additionalDragged * 0.25
       	If Programme.Genre < 9
			Assets.GetSprite("gfx_movie"+Programme.Genre).Draw(Pos.x+7, Pos.y)
     	Else
			Assets.GetSprite("gfx_movie0").Draw(Pos.x+7, Pos.y)
     	EndIf
      Else
        If Pos.x > 520
            If dragable = 0 Then SetAlpha 0.5;SetColor 200,200,200
        EndIf
       	If Programme.Genre < 9
			Assets.GetSprite("gfx_movie"+Programme.Genre).Draw(Pos.x, Pos.y)
     	Else
			Assets.GetSprite("gfx_movie0").Draw(Pos.x, Pos.y)
     	EndIf
      EndIf
      SetColor 255,255,255
      SetAlpha 1
    End Method

End Type

'Programmeblocks used in MovieAgency
Type TMovieAgencyBlocks Extends TSuitcaseProgrammeBlocks
  Field slot:Int = 0 {saveload = "normal"}
  Field Link:TLink
  Global DragAndDropList:TList = CreateList()
  Global List:TList = CreateList()
  Global AdditionallyDragged:Int =0
  Global DebugMode:Byte = 0
  Global HoldingType:Byte = 0

  Function LoadAll(loadfile:TStream)
    TMovieAgencyBlocks.List.Clear()
	Print "cleared movieagencyblocks:" + TMovieAgencyBlocks.List.Count()
    Local BeginPos:Int = Stream_SeekString("<MOVIEAGENCYB/>", loadfile) + 1
    Local EndPos:Int = Stream_SeekString("</MOVIEAGENCYB>",loadfile)  -15
    loadfile.Seek(BeginPos)
    TMovieAgencyBlocks.AdditionallyDragged:Int = ReadInt(loadfile)
	Local MovieAgencyBlocksCount:Int = ReadInt(loadfile)
	If MovieAgencyBlocksCount > 0
	Repeat
      Local MovieAgencyBlocks:TMovieAgencyBlocks = New TMovieAgencyBlocks
	  MovieAgencyBlocks.Pos.Load(Null)
	  MovieAgencyBlocks.OrigPos.Load(Null)
	  MovieAgencyBlocks.StartPos.Load(Null)
	  MovieAgencyBlocks.StartPosBackup.Load(Null)
	  Local ProgrammeID:Int  = ReadInt(loadfile)
	  If ProgrammeID >= 0
	    MovieAgencyBlocks.Programme = TProgramme.GetProgramme(ProgrammeID)
 	    MovieAgencyBlocks.width  = Assets.GetSprite("gfx_movie0").w-1
 	    MovieAgencyBlocks.height = Assets.GetSprite("gfx_movie0").h
	  EndIf
	  MovieAgencyBlocks.dragable= ReadInt(loadfile)
	  MovieAgencyBlocks.dragged = ReadInt(loadfile)
	  MovieAgencyBlocks.slot	= ReadInt(loadfile)
	  MovieAgencyBlocks.StartPos.Load(Null)
	  MovieAgencyBlocks.owner   = ReadInt(loadfile)
	  MovieAgencyBlocks.Link = TMovieAgencyBlocks.List.AddLast(MovieAgencyBlocks)

	  ReadString(loadfile,5) 'finishing string (eg. "|PRB|")
	Until loadfile.Pos() >= EndPos
	EndIf
	Print "loaded movieagencyblocks"
  End Function

	Function SaveAll()
		Local MovieAgencyBlocksCount:Int = 0
		LoadSaveFile.xmlBeginNode("ALLMOVIEAGENCYBLOCKS")
			LoadSaveFile.xmlWrite("ADDITIONALLYDRAGGED",	TMovieAgencyBlocks.AdditionallyDragged)
			For Local MovieAgencyBlocks:TMovieAgencyBlocks= EachIn TMovieAgencyBlocks.List
				If MovieAgencyBlocks <> Null Then If MovieAgencyBlocks.owner <= 0 Then MovieAgencyBlocksCount:+1
			Next
			LoadSaveFile.xmlWrite("MOVIEAGENCYBLOCKSCOUNT",	MovieAgencyBlocksCount)
			For Local MovieAgencyBlocks:TMovieAgencyBlocks= EachIn TMovieAgencyBlocks.List
				If MovieAgencyBlocks <> Null Then MovieAgencyBlocks.Save()
			Next
		LoadSaveFile.xmlCloseNode()
	End Function

	Method Save()
		LoadSaveFile.xmlBeginNode("MOVIEAGENCYBLOCK")
			Local typ:TTypeId = TTypeId.ForObject(Self)
			For Local t:TField = EachIn typ.EnumFields()
				If t.MetaData("saveload") = "normal" Or t.MetaData("saveload") = "normalExt"
					LoadSaveFile.xmlWrite(Upper(t.name()), String(t.Get(Self)))
				EndIf
			Next
			If Self.Programme <> Null
				LoadSaveFile.xmlWrite("PROGRAMMEID", Self.programme.id)
			Else
				LoadSaveFile.xmlWrite("PROGRAMMEID",		"-1")
			EndIf
		LoadSaveFile.xmlCloseNode()
	End Method


  Method Buy:Int(PlayerID:Int = -1)
  	If PlayerID = -1 Then PlayerID = Game.playerID
	If Player[PlayerID].finances[TFinancials.GetDayArray(Game.day)].PayMovie(Programme.ComputePrice())
  		owner = PlayerID
		Programme.used = PlayerID
		Return 1
	EndIf
	Return 0
  End Method

  Method Sell(bymakler:Byte=0, PlayerID:Int=-1)
  	If PlayerID = -1 Then PlayerID = Game.playerID
    If Game.networkgame Then If Network.IsConnected Then Network.SendProgrammeCollectionChange(PlayerID, programme, 0) 'remove from collection
    Player[PlayerID].finances[TFinancials.GetDayArray(Game.day)].SellMovie(Programme.ComputePrice())
    'If bymakler Then TMovieAgencyBlocks.RemoveBlockByProgramme(Programme, owner)
	Self.StartPos.SetPos(Self.StartPosBackup)
	Self.StartPosBackup.SetY(0)
	If Self.StartPos.y < 240 And Self.StartPos.x > 760 Then Self.SetCoords(Self.StartPos.x,Self.StartPos.y,Self.StartPos.x,Self.StartPos.y)
	programme.used = 0
   	owner = 0
    If Self.DebugMode=1 Then Print "Programme "+Programme.title +" sold"
  End Method

  Function RemoveBlockByProgramme(programme:TProgramme, playerID:Int=0)
    If programme <> Null
	  Local movieblockarray:Object[]
	  movieblockarray = TMovieAgencyBlocks.List.ToArray()
	  For Local j:Int = 0 To movieblockarray.Length-1
        If TMovieAgencyBlocks(movieblockarray[j]).Programme <> Null
	      If TMovieAgencyBlocks(movieblockarray[j]).Programme.title = programme.title
  	        movieblockarray[j] = Null
          EndIf
	    EndIf
	  Next
	  TMovieAgencyBlocks.List.Clear()
	  TMovieAgencyBlocks.List = TList.FromArray(movieblockarray)
	EndIf
  End Function

  'refills missing blocks in the movieagency
  'has to be excluded from other functions to make it the way, that a player has to leave the movieagency
  'to get "new" movies to buy
  Function ReFillBlocks:Int()
    Local movierow:Byte[11]
    Local seriesrow:Byte[7]
	For Local locObject:TMovieAgencyBlocks = EachIn TMovieAgencyBlocks.List
      If locobject.Programme <> Null
	    If locobject.Pos.y = 134-70     Then movierow[ Int( (locobject.Pos.x-600)/15 ) ] = 1
        If locobject.Pos.y = 134-70+110 Then seriesrow[ Int( (locobject.Pos.x-600)/15 ) ] = 1
      Else
	    If locobject.Pos.y = 134-70     Then locobject.Programme = TProgramme.GetRandomMovie()
        If locobject.Pos.y = 134-70+110 Then locobject.Programme = TProgramme.GetRandomSerie()
	  EndIf
	Next
	For Local i:Byte = 0 To seriesrow.length-2
	  If seriesrow[i] <> 1 Then  TMovieAgencyBlocks.Create(TProgramme.GetRandomSerie(),i+20, 0)
	Next
	For Local i:Byte = 0 To movierow.length-2
	  If movierow[i] <> 1 Then TMovieAgencyBlocks.Create(TProgramme.GetRandomMovie(),i, 0)
	Next
  End Function

  Function ProgrammeToPlayer:Int(playerID:Int)
    TArchiveProgrammeBlocks.ClearSuitcase(playerID)
   SortList(TMovieAgencyBlocks.List)
   	For Local locObject:TMovieAgencyBlocks = EachIn TMovieAgencyBlocks.List
     If locobject.Pos.y > 240 And locobject.owner = playerID
       If     locobject.Programme.isMovie Then Player[playerID].ProgrammeCollection.AddMovie(locobject.Programme,playerID)
       If Not locobject.Programme.isMovie Then Player[playerID].ProgrammeCollection.AddSerie(locobject.Programme,playerID)
      Local x:Int=0
      Local y:Int=0
      x=600+locobject.slot*15 'ImageWidth(gfx_movie[0])
      y=134-70 'ImageHeight(gfx_movie[0])
 	  If locobject.slot >= 20 And locobject.slot <= 30 '2. Reihe: Serien
      x=600+(locobject.slot-20)*15 'ImageWidth(gfx_movie[0])
      y=134-70 + 110'ImageHeight(gfx_movie[0])
      EndIf
	  LocObject.Pos.SetXY(x, y)
	  LocObject.OrigPos.SetXY(x, y)
	  LocObject.StartPos.SetXY(x, y)
 	  locobject.owner = 0

 	  LocObject.dragable = 1
	  If locobject.Programme.isMovie
			locobject.Programme = TProgramme.GetRandomMovie(-1)
	  Else
			locobject.Programme = TProgramme.GetRandomSerie(-1)
	  EndIf
	 EndIf
    Next
	TMovieAgencyBlocks.ReFillBlocks()
  End Function

  'if owner = 0 then its a block of the adagency, otherwise it's one of the player'
  Function Create:TMovieAgencyBlocks(Programme:TProgramme, slot:Int=0, owner:Int=0)
	If Programme <> Null
	  Local LocObject:TMovieAgencyBlocks=New TMovieAgencyBlocks
      Local x:Int=600+slot*15 'ImageWidth(gfx_movie[0])
      Local y:Int=134-70 'ImageHeight(gfx_movie[0])
 	  If slot >= 20 And slot <= 30 '2. Reihe: Serien
		  x=600+(slot-20)*15
		  y=134-70 + 110
      EndIf
 	  If owner > 0 Then y = 260
	  LocObject.Pos			=TPosition.Create(x, y)
	  LocObject.OrigPos		=TPosition.Create(x, y)
	  LocObject.StartPos	=TPosition.Create(x, y)
	  LocObject.StartPosBackup =TPosition.Create(x, y)
 	  LocObject.slot = slot
 	  locObject.owner = owner
 	  'hier noch als variablen uebernehmen
 	  LocObject.dragable = 1
 	  LocObject.width  = Assets.GetSprite("gfx_movie0").w-1
 	  LocObject.height = Assets.GetSprite("gfx_movie0").h
 	  LocObject.Programme = Programme
 	  If Not List Then List = CreateList()
 	  LocObject.Link = List.AddLast(LocObject)
 	  SortList List

If owner = 0
      Local DragAndDrop:TDragAndDrop = New TDragAndDrop
 	    DragAndDrop.slot = slot + 200
 	    DragAndDrop.pos.setXY(x,y)
 	    DragAndDrop.used = 1
 	    DragAndDrop.w = Assets.GetSprite("gfx_movie0").w
 	    DragAndDrop.h = Assets.GetSprite("gfx_movie0").h
        TMovieAgencyBlocks.DragAndDropList.AddLast(DragAndDrop)
Else
      LocObject.dragable = 0
EndIf
'      Print "created movieblock"+locobject.y
 	  Return LocObject
	 EndIf
    Return Null
  End Function

	Method SetDragable(_dragable:Int = 1)
		dragable = _dragable
	End Method

    Method Compare:Int(otherObject:Object)
       Local s:TMovieAgencyBlocks = TMovieAgencyBlocks(otherObject)
       If Not s Then Return 1                  ' Objekt nicht gefunden, an das Ende der Liste setzen
  '      DebugLog s.title + " "+s.sendtime + " "+sendtime + " "+((dragged * 100 * sendtime + sendtime)-(s.dragged * 100 * s.sendtime + sendtime))
        Return (dragged * 100)-(s.dragged * 100)
    End Method

    Method GetSlotOfBlock:Int()
    	If Pos.x = 589
    	  Return 12+(Int(Floor(StartPos.y- 17) / 30))
    	EndIf
    	If Pos.x = 262
    	  Return 1*(Int(Floor(StartPos.y - 17) / 30))
    	EndIf
    	Return -1
    End Method

   Function DrawAll(DraggingAllowed:Byte)
		For Local locObject:TMovieAgencyBlocks = EachIn TMovieAgencyBlocks.List
			If locobject.owner <= 0 Or locobject.owner = Game.playerID then locObject.Draw(TMovieAgencyBlocks.AdditionallyDragged)
		Next
	End Function

	Function UpdateAll(DraggingAllowed:Byte)
		Local localslot:Int = 0 								'slot in suitcase
		Local imgWidth:Int  = Assets.GetSprite("gfx_movie0").w

		TMovieAgencyBlocks.holdingType = 0						'reset type of holding block (0 = no block, 1 = own, 2 = agency)
		TMovieAgencyBlocks.AdditionallyDragged = 0				'reset additional dragged objects
		SortList TMovieAgencyBlocks.List						'sort blocklist

		'search for obj of the player (and set coords from left to right of suitcase)
		For Local locObj:TMovieAgencyBlocks = EachIn TMovieAgencyBlocks.List
			If locObj.Programme <> Null
			'	locObj.dragable = True
				'its a programme of the player, so set it to the coords of the suitcase
				If locObj.owner = Game.playerID
					If locObj.StartPosBackup = Null Then Print "StartPosBackup missing";locObj.StartPosBackup = TPosition.Create(0,0)
					If locObj.StartPosBackup.y = 0 Then locObj.StartPosBackup.SetPos(locObj.StartPos)
					locObj.SetCoords(550+imgWidth*localslot, 267, 550+imgWidth*localslot, 267)
					locObj.dragable = True
					localslot:+1
				End If
			EndIf
		Next

		ReverseList TMovieAgencyBlocks.list 					'reorder: first are dragged obj then not dragged

		For Local locObj:TMovieAgencyBlocks = EachIn TMovieAgencyBlocks.List
			If locObj.Programme <> Null
				locObj.dragable = 1
				If locObj.Programme.ComputePrice() > Player[Game.playerID].finances[0].money And..
				   locObj.owner <> Game.playerID And..
				   locObj.dragged = 0  Then locObj.dragable = 0


				'which kind of block is the player keeping dragged?
			    If locObj.dragged
					If locObj.owner = game.playerID	Then TMovieAgencyBlocks.HoldingType = 1
					If locObj.owner <= 0			Then TMovieAgencyBlocks.HoldingType = 2
			    EndIf
				'block is dragable and from movieagency or player
				If DraggingAllowed And locObj.dragable And (locObj.owner <= 0 Or locObj.owner = Game.playerID)
					'if right mbutton clicked and block dragged: reset coord of block
					If MOUSEMANAGER.IsHit(2) And locObj.dragged
						locObj.SetCoords(locObj.StartPos.x, locObj.StartPos.y)
						locObj.dragged = False
						MOUSEMANAGER.resetKey(2)
					EndIf

					'if left mbutton clicked: sell, buy, drag, drop, replace with underlaying block...
					If MouseManager.IsHit(1)
						'search for underlaying block (we have a block dragged already)
						If locObj.dragged
							'obj over employee - so buy or sell
							If functions.MouseIn(20,65, 135, 225)
                          		If locObj.StartPos.y <= 240 And locObj.owner <> Game.playerID Then locObj.Buy()
                          		If locObj.StartPos.y >  240 And locObj.owner =  Game.playerID Then locObj.Sell(1)
								locObj.dragged = False
							EndIf
							'obj over suitcase - so buy ?
							If functions.MouseIn(540,250,190,360)
                          		If locObj.StartPos.y <= 240 And locObj.Pos.y > 240  And locObj.owner <> Game.playerID Then locObj.Buy()
								locObj.dragged = False
							EndIf
							'obj over old position in shelf - so sell ?
							If functions.MouseIn(locobj.StartPosBackup.x,locobj.StartPosBackup.y,locobj.width,locobj.height)
                          		If locObj.StartPos.y >  240 And locObj.owner =  Game.playerID Then locObj.Sell()
								locObj.dragged = False
							EndIf

							'block over rect of programme-shelf
							If functions.IsIn(locObj.Pos.x, locObj.Pos.y, 590,30, 190,280)
								'want to drop in origin-position
								If locObj.ContainingCoord(MouseX(), MouseY())
									locObj.dragged = False
									MouseManager.resetKey(1)
									'Print "movieagency: dropped to original position"
								'not dropping on origin: search for other underlaying obj
								Else
									For Local OtherLocObj:TMovieAgencyBlocks = EachIn TMovieAgencyBlocks.List
										If OtherLocObj <> Null
											If OtherLocObj.ContainingCoord(MouseX(), MouseY()) And OtherLocObj <> locObj And OtherLocObj.dragged = False And OtherLocObj.dragable
												If locObj.Programme.isMovie = OtherLocObj.Programme.isMovie
													If game.networkgame Then Network.SendMovieAgencyChange(Network.NET_SWITCH, Game.playerID, OtherlocObj.Programme.id, - 1, locObj.Programme)
													locObj.SwitchBlock(otherLocObj)
													'Print "movieagency: switched - other obj found"
													Exit	'exit enclosing for-loop (stop searching for other underlaying blocks)
												EndIf
												MouseManager.resetKey(1)
											EndIf
										EndIf
									Next
								EndIf	'end: drop in origin or search for other obj underlaying
							EndIf 		'end: block over programme-shelf
						Else			'end: an obj is dragged
							If LocObj.ContainingCoord(MouseX(), MouseY())
								locObj.dragged = 1
								MouseManager.resetKey(1)
							EndIf
						EndIf
					EndIf 				'end: left mbutton clicked
				EndIf					'end: dragable block and player or movieagency is owner
			EndIf 						'end: obj.programme <> NULL

			'if obj dragged then coords to mousecursor+displacement, else to startcoords
			If locObj.dragged = 1
				TMovieAgencyBlocks.AdditionallyDragged :+1
				Local displacement:Int = TMovieAgencyBlocks.AdditionallyDragged *5
				locObj.setCoords(MouseX() - locObj.width/2 - displacement, MouseY() - locObj.height/2 - displacement)
			Else
				locObj.SetCoords(locObj.StartPos.x, locObj.StartPos.y)
			EndIf
		Next
		ReverseList TMovieAgencyBlocks.list 'reorder: first are not dragged obj
  End Function
End Type

'Programmeblocks used in Archive
Type TArchiveProgrammeBlocks Extends TSuitcaseProgrammeBlocks
  Field slot:Int				= 0 {saveload = "normal"}
  Field alreadyInSuitcase:Byte	= 0
  Field owner:Int				= 0 {saveload = "normal"}

  Global List:TList				= CreateList()
  Global DragAndDropList:TList	= CreateList()
  Global AdditionallyDragged:Int= 0

  Function LoadAll(loadfile:TStream)
 	TArchiveProgrammeBlocks.DragAndDropList.Clear()
    Local BeginPos:Int = Stream_SeekString("<ARCHIVEDND/>",loadfile)+1
    Local EndPos:Int = Stream_SeekString("</ARCHIVEDND>",loadfile)  -13
    loadfile.Seek(BeginPos)
	Local DNDCount:Int = ReadInt(loadfile)
    For Local i:Int = 1 To DNDCount
	  Local DragAndDrop:TDragAndDrop = New TDragAndDrop
      DragAndDrop.slot = ReadInt(loadfile)
      DragAndDrop.used = ReadInt(loadfile)
	  DragAndDrop.used = 0
      DragAndDrop.pos.SetXY(ReadInt(loadfile), ReadInt(loadfile))
      DragAndDrop.w = ReadInt(loadfile)
      DragAndDrop.h = ReadInt(loadfile)
	  DragAndDrop.typ = ""
	  'Print "loaded DND: used"+DragAndDrop.used+" x"+DragAndDrop.rectx+" y"+DragAndDrop.recty+" w"+DragAndDrop.rectw
	  ReadString(loadfile,5) 'finishing string (eg. "|DND|")
      If Not TArchiveProgrammeBlocks.DragAndDropList Then TArchiveProgrammeBlocks.DragAndDropList = CreateList()
      TArchiveProgrammeBlocks.DragAndDropList.AddLast(DragAndDrop)
    Next
    SortList TArchiveProgrammeBlocks.DragAndDropList

    BeginPos:Int = Stream_SeekString("<ARCHIVEB/>",loadfile)+1
    EndPos:Int = Stream_SeekString("</ARCHIVEB>",loadfile)  -11
    loadfile.Seek(BeginPos)
    TArchiveProgrammeBlocks.AdditionallyDragged:Int = ReadInt(loadfile)
	Local ArchiveProgrammeBlocksCount:Int = ReadInt(loadfile)
	If ArchiveProgrammeBlocksCount > 0
	Repeat
      Local ArchiveProgrammeBlocks:TArchiveProgrammeBlocks = New TArchiveProgrammeBlocks
	  ArchiveProgrammeBlocks.id = ReadInt(loadfile)
	  ArchiveProgrammeBlocks.Pos.Load(Null)
	  ArchiveProgrammeBlocks.OrigPos.Load(Null)
	  Local ProgrammeID:Int  = ReadInt(loadfile)
	  If ProgrammeID >= 0
	    ArchiveProgrammeBlocks.Programme = TProgramme.GetProgramme(ProgrammeID)
 	    ArchiveProgrammeBlocks.width  = Assets.GetSprite("gfx_movie0").w-1
 	    ArchiveProgrammeBlocks.height = Assets.GetSprite("gfx_movie0").h
	  EndIf
	  ArchiveProgrammeBlocks.dragable= ReadInt(loadfile)
	  ArchiveProgrammeBlocks.dragged = ReadInt(loadfile)
	  ArchiveProgrammeBlocks.slot	= ReadInt(loadfile)
	  ArchiveProgrammeBlocks.StartPos.Load(Null)
	  ArchiveProgrammeBlocks.owner   = ReadInt(loadfile)

	  TArchiveProgrammeBlocks.List.AddLast(ArchiveProgrammeBlocks)

	  ReadString(loadfile,5) 'finishing string (eg. "|PRB|")
	Until loadfile.Pos() >= EndPos
	EndIf
	Print "loaded archiveprogrammeblocks"
  End Function

	Function SaveAll()
		Local ArchiveProgrammeBlocksCount:Int = 0
		LoadSaveFile.xmlBeginNode("ARCHIVEDND")
			'SaveFile.WriteInt(TArchiveProgrammeBlocks.DragAndDropList.Count())
			For Local DragAndDrop:TDragAndDrop = EachIn TArchiveProgrammeBlocks.DragAndDropList
				LoadSaveFile.xmlBeginNode("DND")
					LoadSaveFile.xmlWrite("SLOT",		DragAndDrop.slot)
					LoadSaveFile.xmlWrite("USED",		DragAndDrop.used)
					LoadSaveFile.xmlWrite("X",		DragAndDrop.pos.x)
					LoadSaveFile.xmlWrite("Y",		DragAndDrop.pos.y)
					LoadSaveFile.xmlWrite("W",		DragAndDrop.w)
					LoadSaveFile.xmlWrite("H",		DragAndDrop.h)
				LoadSaveFile.xmlCloseNode()
			Next
		LoadSaveFile.xmlCloseNode()
		LoadSaveFile.xmlBeginNode("ALLARCHIVEPROGRAMMEBLOCKS")
			LoadSaveFile.xmlWrite("ADDITIONALLYDRAGGED", 	TArchiveProgrammeBlocks.AdditionallyDragged)
			For Local ArchiveProgrammeBlocks:TArchiveProgrammeBlocks= EachIn TArchiveProgrammeBlocks.List
				If ArchiveProgrammeBlocks <> Null
					'If ArchiveProgrammeBlocks.owner <= 0 Then
					ArchiveProgrammeBlocksCount:+1
				EndIf
			Next
			LoadSaveFile.xmlWrite("ARCHIVEPROGRAMMEBLOCKSCOUNT", 	ArchiveProgrammeBlocksCount)
			For Local ArchiveProgrammeBlocks:TArchiveProgrammeBlocks= EachIn TArchiveProgrammeBlocks.List
				If ArchiveProgrammeBlocks <> Null Then ArchiveProgrammeBlocks.Save()
			Next
		LoadSaveFile.xmlCloseNode()
	End Function

	Method Save()
  		LoadSaveFile.xmlBeginNode("ARCHIVEPROGRAMMEBLOCK")
			Local typ:TTypeId = TTypeId.ForObject(Self)
			For Local t:TField = EachIn typ.EnumFields()
				If t.MetaData("saveload") = "normal" Or t.MetaData("saveload") = "normalExt"
					LoadSaveFile.xmlWrite(Upper(t.name()), String(t.Get(Self)))
				EndIf
			Next
			If Self.Programme <> Null
				LoadSaveFile.xmlWrite("PROGRAMMEID", Self.programme.id)
			Else
				LoadSaveFile.xmlWrite("PROGRAMMEID",	"-1")
			EndIf
		LoadSaveFile.xmlCloseNode()
	End Method

	'deletes Programmes from Plan (every instance) and from the players collection
	Function ProgrammeToSuitcase:Int(playerID:Int)
		Local myslot:Int=0
		For Local locObject:TArchiveProgrammeBlocks = EachIn TArchiveProgrammeBlocks.List
			If locobject.owner = playerID And Not locobject.alreadyInSuitcase
				TMovieAgencyBlocks.Create(locobject.Programme, myslot, playerID)
				If game.networkgame Then If network.IsConnected Then Network.SendProgrammeCollectionChange(playerID, locobject.programme, 1) 'remove all instances
				'reset audience "sendeausfall"
				If Player[playerID].ProgrammePlan.GetActualProgramme().id = locobject.Programme.id then Player[playerID].audience = 0
				'remove programme
				Player[playerID].ProgrammePlan.RemoveProgramme( locobject.Programme )
				locobject.alreadyInSuitcase = True
				myslot:+1
			EndIf
		Next
	End Function

	Function ClearSuitcase:Int(playerID:Int)
		For Local block:TArchiveProgrammeBlocks=EachIn TArchiveProgrammeBlocks.list
			If block.owner = playerID Then TArchiveProgrammeBlocks.List.Remove(block)
		Next
	End Function

	'if a archiveprogrammeblock is "deleted", the programme is readded to the players programmecollection
	'afterwards it deletes the archiveprogrammeblock
	Method ReAddProgramme:Int(playerID:Int)
		Player[playerID].ProgrammeCollection.AddProgramme(Self.Programme,playerID)
		'remove blocks which may be already created for having left the archive before re-adding it...
		TMovieAgencyBlocks.RemoveBlockByProgramme(Self.Programme, playerID)

		If game.networkgame Then If network.IsConnected Then Network.SendProgrammeCollectionChange(playerID, Self.programme, 2) 'readd

		Self.alreadyInSuitcase = False
		List.Remove(Self)
	End Method

	Method RemoveProgramme:Int(programme:TProgramme, owner:Int=0)
		If game.networkgame Then If network.IsConnected Then Network.SendProgrammeCollectionChange(owner, programme, 3) 'remove from collection
		Player[owner].ProgrammeCollection.RemoveProgramme(programme, owner)
	End Method

	'if owner = 0 then its a block of the adagency, otherwise it's one of the player'
	Function Create:TArchiveProgrammeBlocks(Programme:TProgramme, slot:Int=0, owner:Int=0)
		If owner < 0 Then owner = game.playerID
		Local obj:TArchiveProgrammeBlocks=New TArchiveProgrammeBlocks
		Local x:Int=60+slot*15 'ImageWidth(gfx_movie[0])
		Local y:Int=285 'ImageHeight(gfx_movie[0])
		obj.Pos		= TPosition.Create(x, y)
		obj.OrigPos	= TPosition.Create(x, y)
		obj.StartPos	= TPosition.Create(x, y)
		obj.slot		= slot
		obj.owner 	= owner
		obj.dragable	= 1
		obj.width  	= Assets.GetSprite("gfx_movie0").w
		obj.height 	= Assets.GetSprite("gfx_movie0").h
		obj.Programme = Programme
		List.AddLast(obj)
		SortList List
		Return obj
	End Function

	'creates a programmeblock which is already dragged (used by movie/series-selection)
    'erstellt einen gedraggten Programmblock (genutzt von der Film- und Serienauswahl)
	Function CreateDragged:TArchiveProgrammeBlocks(programme:TProgramme, owner:Int =-1)
		Local obj:TArchiveProgrammeBlocks= TArchiveProgrammeBlocks.Create(programme, 0, owner)
		obj.Pos		= TPosition.Create(MouseX(), MouseY())
		obj.StartPos= TPosition.Create(0, 0) 'ProgrammeBlock.x, ProgrammeBlock.y
		'dragged
		obj.dragged	= 1
		TArchiveProgrammeBlocks.AdditionallyDragged :+ 1

		Return obj
	End Function

    Method Compare:Int(otherObject:Object)
		Local s:TArchiveProgrammeBlocks = TArchiveProgrammeBlocks(otherObject)
		If Not s Then Return 1                  ' Objekt nicht gefunden, an das Ende der Liste setzen
		Return (dragged * 100)-(s.dragged * 100)
    End Method

    Method GetSlotOfBlock:Int()
    	If Pos.x = 589 then Return 12+(Int(Floor(StartPos.y - 17) / 30))
    	If Pos.x = 262 then Return    (Int(Floor(StartPos.y - 17) / 30))
    	Return -1
    End Method

	Function DrawAll(DraggingAllowed:Byte)
		SortList TArchiveProgrammeBlocks.List
		For Local locObject:TArchiveProgrammeBlocks = EachIn TArchiveProgrammeBlocks.List
			If locobject.owner <= 0 Or locobject.owner = Game.playerID
				locObject.Draw(TArchiveProgrammeBlocks.additionallyDragged)
			EndIf
		Next
	End Function

    Function UpdateAll(DraggingAllowed:Byte)
		Local number:Int = 0
		Local localslot:Int = 0 'slot in suitcase

		SortList TArchiveProgrammeBlocks.List
		For Local locObject:TArchiveProgrammeBlocks = EachIn TArchiveProgrammeBlocks.List
			If DraggingAllowed And locobject.owner <= 0 Or locobject.owner = Game.playerID
				number :+ 1
				If MOUSEMANAGER.IsHit(2) And locObject.dragged = 1
					locObject.ReAddProgramme(game.playerID)
					MOUSEMANAGER.resetKey(2)
					Exit
				EndIf

				If MOUSEMANAGER.IsHit(1)
					If locObject.dragged = 0 And locObject.dragable = 1
						If functions.MouseIn(locObject.Pos.x, locobject.Pos.y, locObject.width, locObject.height)
							locObject.dragged = 1
						EndIf
					ElseIf locobject.dragable = 1
						Local realDNDfound:Int = 0
						If MOUSEMANAGER.IsHit(1)
							locObject.dragged = 0
							realDNDfound = 0
							For Local DragAndDrop:TDragAndDrop = EachIn TArchiveProgrammeBlocks.DragAndDropList
								'don't allow dragging of series into the agencies movie-row and wise versa
								If DragAndDrop.CanDrop(MouseX(),MouseY(), "archiveprogrammeblock") = 1 And (DragAndDrop.pos.x < 50+200 Or DragAndDrop.pos.x > 50+Assets.GetSprite("gfx_movie0").w*(localslot-1))
									For Local OtherlocObject:TArchiveProgrammeBlocks= EachIn TArchiveProgrammeBlocks.List
										If DraggingAllowed And otherlocobject.owner <= 0 'on plan and not in elevator
											'is there a NewsBlock positioned at the desired place?
											If MOUSEMANAGER.IsHit(1) And OtherlocObject.dragable = 1 And OtherlocObject.Pos.isSame(DragAndDrop.pos)
												OtherlocObject.dragged = 1
											EndIf
										EndIf
									Next
									LocObject.Pos.SetPos(DragAndDrop.pos)
									locobject.RemoveProgramme(locobject.Programme, locobject.owner)
									LocObject.StartPos.SetPos(LocObject.Pos)
									realDNDfound =1
									Exit 'exit loop-each-dragndrop, we've already found the right position
								EndIf
							Next
							'suitcase as dndzone
							If Not realDNDfound And functions.IsIn(MouseX(),MouseY(),50-10,280-20,200+2*10,100+2*20)
								For Local DragAndDrop:TDragAndDrop = EachIn TArchiveProgrammeBlocks.DragAndDropList
									If functions.IsIn(DragAndDrop.pos.x, DragAndDrop.pos.y, 50,280,200,100)
										If DragAndDrop.pos.x >= 55 + Assets.GetSprite("gfx_contracts_base").w * (localslot)
											If DragAndDrop.used = 0 'and DragAndDrop.slot > (localslot) Then
												DragAndDrop.used =1
												LocObject.Pos.SetPos(DragAndDrop.pos)
												LocObject.StartPos.SetPos(LocObject.Pos)
												Exit 'exit loop-each-dragndrop, we've already found the right position
											EndIf
										EndIf
									EndIf
								Next
							EndIf
							'no drop-area under Adblock (otherwise this part is not executed - "exit"), so reset position
							If Abs(locObject.Pos.x - locObject.StartPos.x)<=1 And..
							   Abs(locObject.Pos.y - locObject.StartPos.y)<=1
								locObject.dragged    = 0
								LocObject.Pos.SetPos(LocObject.StartPos)
								SortList TArchiveProgrammeBlocks.List
							EndIf
						EndIf
					EndIf
				EndIf
				If locObject.dragged = 1
				  TArchiveProgrammeBlocks.AdditionallyDragged :+1
				  LocObject.Pos.SetXY(MouseX() - locObject.width /2 - TArchiveProgrammeBlocks.AdditionallyDragged *5,..
									  MouseY() - locObject.height /2 - TArchiveProgrammeBlocks.AdditionallyDragged *5)
				EndIf
				If locObject.dragged = 0
					If locObject.StartPos.x = 0 And locObject.StartPos.y = 0
						locObject.dragged = 1
						TArchiveProgrammeBlocks.AdditionallyDragged:+ 1
					Else
						LocObject.Pos.SetPos(LocObject.StartPos)
					EndIf
				EndIf
			EndIf
			locobject.dragable = 1
		Next
		TArchiveProgrammeBlocks.AdditionallyDragged = 0
	End Function
End Type

'Programmeblocks used in Archive
Type TAuctionProgrammeBlocks
  Field x:Int = 0 {saveload = "normal"}
  Field y:Int = 0 {saveload = "normal"}
  Field imageWithText:TImage = Null
  Field Programme:TProgramme
  Field slot:Int = 0 {saveload = "normal"}
  Field Bid:Int[5]
  Field uniqueID:Int = 0 {saveload = "normal"}
  Field Link:TLink
  Global LastUniqueID:Int =0
  Global List:TList = CreateList()
  Global DrawnFirstTime:Byte = 0

  Function ProgrammeToPlayer()
    For Local locObject:TAuctionProgrammeBlocks = EachIn TAuctionProgrammeBlocks.List
      If locObject.Programme <> Null And locObject.Bid[0] > 0 And locObject.Bid[0] <= 4
	    Player[locobject.Bid[0]].ProgrammeCollection.AddProgramme(locobject.Programme,locObject.Bid[0])
		Print "player "+Player[locobject.Bid[0]].name + " won the auction for: "+locobject.Programme.title
		Repeat
		  LocObject.Programme = TProgramme.GetRandomMovieWithMinPrice(250000)
		Until LocObject.Programme <> Null
		locObject.imageWithText = Null
		For Local i:Int = 0 To 4
	 	  LocObject.Bid[i] = 0
		Next
      End If
    Next

  End Function

  Function LoadAll(loadfile:TStream)
    TAuctionProgrammeBlocks.List.Clear()
	Print "cleared auctionblocks:"+TAuctionProgrammeBlocks.List.Count()
    Local BeginPos:Int = Stream_SeekString("<ARCHIVEB/>",loadfile)+1
    Local EndPos:Int = Stream_SeekString("</AUCTIONB>",loadfile)  -11
    loadfile.Seek(BeginPos)
	Local AuctionProgrammeBlocksCount:Int = ReadInt(loadfile)
	If AuctionProgrammeBlocksCount > 0
	Repeat
      Local AuctionProgrammeBlocks:TAuctionProgrammeBlocks = New TAuctionProgrammeBlocks
	  AuctionProgrammeBlocks.uniqueID = ReadInt(loadfile)
	  AuctionProgrammeBlocks.x 	= ReadInt(loadfile)
	  AuctionProgrammeBlocks.y   = ReadInt(loadfile)
	  Local ProgrammeID:Int  = ReadInt(loadfile)
	  If ProgrammeID >= 0
	    AuctionProgrammeBlocks.Programme = TProgramme.GetProgramme(ProgrammeID)
	  EndIf
	  AuctionProgrammeBlocks.slot	= ReadInt(loadfile)
	  AuctionProgrammeBlocks.Bid[0]	= ReadInt(loadfile)
	  AuctionProgrammeBlocks.Bid[1] = ReadInt(loadfile)
	  AuctionProgrammeBlocks.Bid[2] = ReadInt(loadfile)
	  AuctionProgrammeBlocks.Bid[3] = ReadInt(loadfile)
	  AuctionProgrammeBlocks.Bid[4] = ReadInt(loadfile)
	  AuctionProgrammeBlocks.Link   = TAuctionProgrammeBlocks.List.AddLast(AuctionProgrammeBlocks)

	  ReadString(loadfile,5) 'finishing string (eg. "|PRB|")
	Until loadfile.Pos() >= EndPos
	EndIf
	Print "loaded auctionprogrammeblocks"
  End Function

	Function SaveAll()
	    Local AuctionProgrammeBlocksCount:Int = 0
		For Local AuctionProgrammeBlocks:TAuctionProgrammeBlocks= EachIn TAuctionProgrammeBlocks.List
			If AuctionProgrammeBlocks <> Null Then AuctionProgrammeBlocksCount:+1
		Next
		LoadSaveFile.xmlBeginNode("ALLAUCTIONPROGRAMMEBLOCKS")
			LoadSaveFile.xmlWrite("AUCTIONPROGRAMMEBLOCKSCOUNT",	AuctionProgrammeBlocksCount)
			For Local AuctionProgrammeBlocks:TAuctionProgrammeBlocks= EachIn TAuctionProgrammeBlocks.List
				If AuctionProgrammeBlocks <> Null Then AuctionProgrammeBlocks.Save()
			Next
		LoadSaveFile.xmlCloseNode()
	End Function

	Method Save()
		LoadSaveFile.xmlBeginNode("CONTRACTBLOCK")
			Local typ:TTypeId = TTypeId.ForObject(Self)
			For Local t:TField = EachIn typ.EnumFields()
				If t.MetaData("saveload") = "normal" Or t.MetaData("saveload") = "normalExt"
					LoadSaveFile.xmlWrite(Upper(t.name()), String(t.Get(Self)))
				EndIf
			Next
			If Self.Programme <> Null
				LoadSaveFile.xmlWrite("PROGRAMMEID",	Self.programme.id)
			Else
				LoadSaveFile.xmlWrite("PROGRAMMEID", "-1")
			EndIf
			LoadSaveFile.xmlWrite("BID0", Self.Bid[0] )
			LoadSaveFile.xmlWrite("BID1", Self.Bid[1] )
			LoadSaveFile.xmlWrite("BID2", Self.Bid[2] )
			LoadSaveFile.xmlWrite("BID3", Self.Bid[3] )
			LoadSaveFile.xmlWrite("BID4", Self.Bid[4] )
		LoadSaveFile.xmlCloseNode()
	End Method

  Function Create:TAuctionProgrammeBlocks(Programme:TProgramme, slot:Int=0)
	  Local LocObject:TAuctionProgrammeBlocks=New TAuctionProgrammeBlocks
      Local x:Int=0
      Local y:Int=0
	  x = 140+((slot+1) Mod 2)* 260
	  y = 75+ Ceil((slot-1) / 2)*60
 	  LocObject.x = x
 	  LocObject.y = y
	  LocObject.Bid[0] = 0
	  LocObject.Bid[1] = 0
	  LocObject.Bid[2] = 0
	  LocObject.Bid[3] = 0
	  LocObject.Bid[4] = 0
 	  LocObject.slot = slot
 	  LocObject.Programme = Programme
 	  If Not List Then List = CreateList()
 	  List.AddLast(LocObject)
 	  SortList List
 	  Return LocObject
	End Function

  Method Compare:Int(otherObject:Object)
       Local s:TArchiveProgrammeBlocks = TArchiveProgrammeBlocks(otherObject)
       If Not s Then Return 1                  ' Objekt nicht gefunden, an das Ende der Liste setzen
  '      DebugLog s.title + " "+s.sendtime + " "+sendtime + " "+((dragged * 100 * sendtime + sendtime)-(s.dragged * 100 * s.sendtime + sendtime))
        Return (slot)-(s.slot)
    End Method

    'draw the Block inclusive text
    'zeichnet den Block inklusive Text
    Method Draw()

	  Local HighestBidder:String = ""
	  Local HighestBid:Int = Programme.ComputePrice()
	  Local NextBid:Int = 0
	  If Bid[0]>0 And Bid[0] <=4 Then If Bid[ Bid[0] ] <> 0 Then HighestBid = Bid[ Bid[0] ]
	  NextBid = HighestBid
      If HighestBid < 100000
	    NextBid :+ 10000
	  Else If HighestBid >= 100000 And HighestBid < 250000
	    NextBid :+ 25000
	  Else If HighestBid >= 250000 And HighestBid < 750000
	    NextBid :+ 50000
	  Else If HighestBid >= 750000
	    NextBid :+ 75000
	  EndIf

	  SetColor 255,255,255  'normal
	    If imagewithtext <> Null And Self.DrawnFirstTime > 20
	      DrawImage(imagewithtext,x,y)
	    Else
		  If Self.DrawnFirstTime < 30 Then Self.DrawnFirstTime:+1
		  Assets.GetSprite("gfx_auctionmovie").Draw(x,y)
	      FontManager.baseFont.drawBlock(Programme.title, x+31,y+5, 215,20)
	      FontManager.baseFont.drawBlock("Preis:"+HighestBid+"€", x+31,y+20, 215,20,2,Null, 100,100,100,1)
	      FontManager.baseFont.drawBlock("Bieten:"+NextBid+"€", x+31,y+33, 215,20,2,Null, 0,0,0,1)
          If Player[Bid[0]] <> Null
    	    HighestBidder = Player[Bid[0]].name
	        Local colr:Int = Player[Bid[0]].color.colr'+900
	        Local colg:Int = Player[Bid[0]].color.colg'+900
	        Local colb:Int = Player[Bid[0]].color.colb'+900
		    If colr > 255 Then colr = 255
		    If colg > 255 Then colg = 255
		    If colb > 255 Then colb = 255
'			SetImageFont FontManager.GW_GetFont("Default", 10)
			SetAlpha 1.0;FontManager.GetFont("Default", 10).drawBlock(HighestBidder, x + 33, y + 35, 150, 20, 0, colr - 200, colg - 200, colb - 200, 1)
			SetAlpha 1.0;FontManager.GetFont("Default", 10).drawBlock(HighestBidder, x + 32, y + 34, 150, 20, 0, colr - 150, colg - 150, colb - 150, 1)
	        Local pixmap:TPixmap = GrabPixmap(x+33-2,y+35-2,TextWidth(HighestBidder)+4,TextHeight(HighestBidder)+3)
			pixmap = ConvertPixmap(pixmap, PF_RGBA8888)
            blurPixmap(pixmap, 0.6)
			DrawPixmap(YFlipPixmap(pixmap), x+33-2,y+35-2 + pixmap.height)
			SetAlpha 1.0;FontManager.GetFont("Default", 10).drawBlock(HighestBidder, x + 32, y + 34, 150, 20, 0, colr, colg, colb, 1)
		  EndIf
		  Imagewithtext = TImage.Create(Assets.GetSprite("gfx_auctionmovie").w,Assets.GetSprite("gfx_auctionmovie").h-1,1,0,255,0,255)
		  Imagewithtext.pixmaps[0] = GrabPixmap(x,y,Assets.GetSprite("gfx_auctionmovie").w,Assets.GetSprite("gfx_auctionmovie").h-1)
	    EndIf
	  SetColor 255,255,255
      SetAlpha 1
    End Method


  Function DrawAll(DraggingAllowed:Byte)
      SortList TAuctionProgrammeBlocks.List
      For Local locObject:TAuctionProgrammeBlocks = EachIn TAuctionProgrammeBlocks.List
        locObject.Draw()
      Next
  End Function

	Method SetBid(playerID:Int, price:Int)
		If Player[playerID].finances[TFinancials.GetDayArray(Game.day)].PayProgrammeBid(price) = True
			If Player[Self.Bid[0]] <> Null Then
				Player[Self.Bid[0]].finances[TFinancials.GetDayArray(game.day)].GetProgrammeBid(Self.Bid[Self.Bid[0]])
				Self.Bid[Self.Bid[0]] = 0
			EndIf
			Self.Bid[0] = playerID
			Self.Bid[playerID] = price
			Self.imageWithText = Null
		EndIf
	End Method

	Function UpdateAll(DraggingAllowed:Byte)
		SortList TAuctionProgrammeBlocks.List
		local mouseHit:int = MOUSEMANAGER.IsHit(1)
		For Local locObject:TAuctionProgrammeBlocks = EachIn TAuctionProgrammeBlocks.List
			If mouseHit and functions.IsIn(MouseX(), MouseY(), locObject.x, locObject.y, Assets.GetSprite("gfx_auctionmovie").w, Assets.GetSprite("gfx_auctionmovie").h) AND locObject.Bid[0] <> game.playerID
				Local HighestBid:Int = locObject.Programme.ComputePrice()
				Local NextBid:Int = 0
				If locObject.Bid[0]>0 And locObject.Bid[0] <=4 Then If locObject.Bid[ locObject.Bid[0] ] <> 0 Then HighestBid = locObject.Bid[ locObject.Bid[0] ]
				NextBid = HighestBid
				If HighestBid < 100000
					NextBid :+ 10000
				Else If HighestBid >= 100000 And HighestBid < 250000
					NextBid :+ 25000
				Else If HighestBid >= 250000 And HighestBid < 750000
					NextBid :+ 50000
				Else If HighestBid >= 750000
					NextBid :+ 75000
				EndIf
	  			If game.networkgame Then Network.SendMovieAgencyChange(Network.NET_BID, game.playerID, NextBid, -1, locObject.Programme)
	  			locObject.SetBid(game.playerID, NextBid)  'set the bid
			EndIf
		Next
	End Function

End Type