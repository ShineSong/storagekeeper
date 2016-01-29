# StorageKeeper
A mod of [Don't Starve Together](http://dontstarvetogether.com/) .It's a reliable storage keeper which able to create storage cluster between same type of container ( eg. treasurechest &amp; largechest &amp; stormchest ) and convey the wares flexible.
## Installation
[Download the latest release](https://github.com/ShineSong/storagekeeper/releases) and extract it into `\Steam\SteamApps\common\Don't Starve Together Beta\mods\`, or find it in the [Steam Workshop](http://steamcommunity.com/sharedfiles/filedetails/?id=598878273).

## Usage
Press `H` (default key) to sort items in your container automatically.

You can indicate what types of item should be put in the storage node.Use mod [DST-SignPlus](http://steamcommunity.com/sharedfiles/filedetails/?id=553665029) add label to chest.Label should contains these words with case sensitive:`Equip,Tool,Res,ResNatu or,ResN,ResArti,ResA,ResHunt,ResH,Food,Gen,Meat,Veg,Seed,Meal,Misc,Pipe`.If you want to designate multi type,please use comma as separater.Or you can use grouped types `Res` and `Food` which equal to `ResNatu,ResArti,ResHunt` and `Gen,Meat,Veg,Seed`.
  
1. Equip(clothes,armor,weapons)
2. Tool(Hammer,shaver,etc.)
3. Res (Resources,include three subtypes)
3.1. ResNatu(cutgrass,log,rocks,flint,twigs,grass,bush,poop,etc.)
3.2. ResArti(cutstone,boards,rope,etc.)
3.3. ResHunt(beefalowool,horn,silk,spidergland,etc.)
4. Food(cookable and perishable)
4.1. Gen(Ice,honey)
4.2. Meat
4.3. Veg
4.4. Seed
5. Meal(meatball,fried fish,etc.)
6. Misc(toys,gems)
7. Pipe(lowest priority,often act as pipe to connection other storage nodes.)

It build container cluster by container's category(e.g. icebox vs chest ) and distance between them.Default search distance is 10,also you can change it in config.Search action is performed recursively so if you want you can build an long distance conveyor by treasurechest.

The chest you opened have the highest priority in storage.So items will fill the current chest slots first.

This mod is very useful when you play with many friends.

## How does it work?
Chaos boxes is big problem when play DST with friend ,especially when you have 4 or more friends shared one camp.Players hard work to collect things will make the storage too mess to find what you want.And the diffusion will waste slots of storage.So I dev this mod to free me from boring frequent arrangement work.

When you sort your chest or icebox, the mod search for the nearby chest and icebox within distance(default 10).Then classify stuffs by categories,e.g. resources,tools,weapons.Next merge the stackable items which can be.Finally push all of them into storage,current opened chest have highest priority so the current container will be filled first.

## Release History
### v1.2.8 29/Jan/2016
- Fix : Pipe label will cause game crack.
- Fix : Add Birchnut to Seed label.

### v1.2.7 28/Jan/2016
- Add : Support for DS version.

### v1.2.6 28/Jan/2016
- Add : More detail food types,Meat,Seed,Veg,Gen.
- Add : Grouped label:Food,Res.

### v1.2.5 21/Jan/2016
- Add : Alias of content type.ResA,ResN,ResH.
- Fix : Stormcellar cannot be arranged.

### v1.2.4 18/Jan/2016
- Change : Enlarge the upper bound and default value of radius. 

### v1.2.3 16/Jan/2016
- Fix : same bug as v1.2.2 - 1.

### v1.2.2 16/Jan/2016
- Fix : Some container may overflowed when arranging.
- Fix : The opened chest have highest priority at current depth.
- Change : type determine algorithm between Food and Meal,more robust.

### v1.2.0 16/Jan/2016
- Add : Add support customized chests:"treasurechest","largechest","cellar","dragonflychest","pandoraschest","skullchest","minotaurchest","bluebox" and "icebox","largeicebox","freezer","deep_freezer".
- Add : Collaborate mechanism with mod [DST-SignPlus] to enhance the ability of storage keeper.
- Add : Use label to indicate what type of items should be Put in.You can designate multi types split with comma.The avaliable type table is blow.
Equip,Tool,ResNatu,ResArti,ResHunt,Food,Meal,Misc,Pipe
- Change : items classified strategy.
- Change : The groupset aggregating algorithm.

### v1.1.3 15/jan/2016
- Fix : If you press sort key without open chest since you login,server will crash.

### v1.1.2 14/jan/2016
- Fix : Turn off the debug flag

### v1.1.1 14/jan/2016
- Fix : Bug of If others opened one chest,the chest will be permanently removed and not be mananged.

### v1.1.0 13/jan/2016
- Fix : Arrangement invoked when user is chatting or using console.
- Fix : Add share lock to prevent items lost when sorting.
- New : Add convey direction feature,when you press sort key twice,you can change the convey direction (to fill this chest or empty it)

### v1.0.0-rc-1 12/Jan/2016
- New : First Release
- New : Basement feature of storage keeper
- New : Storage Cluster by distance

## Legal
Copyright © 2016, Shine Song

Licensed under the GPL.

## Acknowledge
Thanks for the mod [DJPaul's Sort Inventory](https://github.com/paulgibbs/DJPaul-Sort-Inventory) which become a good guide book for me as a beginner modder of DST.

Find this mod on [Github](https://github.com/ShineSong/storagekeeper) at https://github.com/ShineSong/storagekeeper

[Klei Forums](http://forums.kleientertainment.com/topic/62320-mod-releasestorage-keeper/) at

[Steam Workshop](http://steamcommunity.com/sharedfiles/filedetails/?id=598878273) at http://steamcommunity.com/sharedfiles/filedetails/?id=598878273
