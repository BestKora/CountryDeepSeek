## iOS apps Countries created by DeepSeek

 A simple iOS application Countries, which shows all the countries of the World by region (Europe, Asia, Latin America, etc.) 
 and for each country its name and flag. 
 
 If you select a country, then additional information about the population 
 and the size of GDP (gross domestic product) gdp and the country's location on the World map is reported.
 We used World Bank data, but we did not tell the AI ​​either the sites or the data structures, 
 the AI ​​should find all this itself and use them when creating an iOS application.
 
 ![til](https://github.com/BestKora/CountryDeepSeek/blob/5578d9842ee9dfcbf339d0b60fa39b309ba377ba/DeepSeek.gif)

## Technologies used by DeepSeek:

* MVVM design pattern 
* SwiftUI
* async / await
* Swift 6 strict concurrency using @MainActor and marking selection functions as nonisolated or using Task.detached.
* API with Map (position: $position) and Maker
* CLGeocoder() to get more accurate geographic coordinates of the country's capital and Task.detached to run in the background.

## Results of using DeepSeek:
* Decoding JSON data without any problems, but got stuck when mapping country and additional information about population and GDP, 
which is explained by “logical errors” in the design of the World Bank API
* Used a modern async / await system for working with multithreading.
Suggested using @MainActor for View Model for Swift 6 strict concurrency and marking fetch functions as nonisolated.
* At first suggested the old Map API with Map (coordinateRegion: $region, annotationItems: [country]) and MapMaker,
  but after receiving the corresponding warnings, switched to the new API with Map (position: $position) and Maker quite successfully.
* Used CLGeocoder() to get more accurate geographic coordinates of the country's capital and Task.detached to run in the background.
* Poorly holds context: sometimes for already worked out pieces of code it offers code with previous errors,
  so the resulting application code has to be assembled piece by piece at each stage.
* The reasoning is very verbose and long, although very interesting, sometimes it promotes very dubious ideas on iOS coding.
   Reasoning lasts from 184 to 18 seconds, the average time is 50 seconds.
   And in addition, recently you can often see the message “The server is busy. Please try again later.”
* Beginner iOS programmers should be very careful when using reasoning as a training material - too much ambiguous reasoning
  regarding the architecture of iOS applications.    
