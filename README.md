# Combine + UIKit + MVVM

An example of how to bind views / view controllers and view models using Combine and UIKit in a fully reactive way. (If you wish to run this demo, you will need to create a developer account at [Unsplash][1] and add your client ID in Requests.swift).

Checkout the full post on [tapdev][2]

[1]: https://unsplash.com/documentation#creating-a-developer-account
[2]: https://tapdev.co/2021/03/31/a-better-way-to-structure-combine-with-uikit-in-mvvm/

![Screenshot](https://user-images.githubusercontent.com/47152208/113141660-e0eaea80-9221-11eb-8d0f-1c8d5c9a4a7c.png)

The view model has a single bind function, where all of the inputs are transformed into outputs. 

The inputs are user events, which in the case of this demo is a single publisher which feeds the view model with the stream of text coming from the search bar. The outputs are then generated by the view model, and made available for subscription in the view using the ```@Published``` property wrapper. Note that there are *no subscriptions being collected in the view model*. This is made possible using ```assign(to:)``` operator which republishes values to the underlying publishers of ```@Published``` properties. The outputs in this case are an array of photo model objects (the result of the API search) and a boolean value to indicate if search is taking place.

```swift
final class SearchViewModel {

    @Published var photos: [Photo] = []
    @Published var searching: Bool = false

    func bind(searchQuery: AnyPublisher<String, Never>) {

        let search = searchQuery
            .debounce(for: .seconds(0.5), scheduler: DispatchQueue.global())
            .map { URLRequest.searchPhotos(query: $0) }
            .share()

        let photos = search
            .map { API.publisher(for: $0) }
            .switchToLatest()
            .decode(type: SearchPhotos.self, decoder: API.jsonDecoder)
            .replaceError(with: .emptyResults)
            .share()

        photos
            .map(\.results)
            .receive(on: DispatchQueue.main)
            .assign(to: &$photos)

        search
            .map { _ in true }
            .merge(with: photos
                    .map { _ in false }
            .replaceError(with: false)
            .receive(on: DispatchQueue.main)
            .assign(to: &$searching)
    }
}
```

The view controller then subscribes to the outputs of the view model.

```swift
final class SearchViewController: UIViewController {
    
    @IBOutlet weak var activityView: UIActivityIndicatorView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var collectionView: UICollectionView!
    
    private let viewModel = SearchViewModel()
    private var subscriptions = Set<AnyCancellable>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        viewModel.bind(searchQuery: searchBar.textDidChangePublisher)
        
        viewModel.$photos
            .bind(subscriber: collectionView.itemsSubscriber(cellIdentifier: "Cell", cellType: PhotoCell.self, cellConfig: { cell, _, photo in
                cell.bind(photo)
              }))
              .store(in: &subscriptions)
        
        viewModel.$searching
            .sink { [weak activityView] searching in
                searching ? activityView?.startAnimating() : activityView?.stopAnimating()
            }
            .store(in: &subscriptions)
        
        searchBar.searchButtonClickedPublisher
            .sink { [weak searchBar] in
                searchBar?.resignFirstResponder()
            }
            .store(in: &subscriptions)
    }
}
```
