//
//  TodoListViewController.swift
//  DiffableDataSourceTodo
//
//  Created by koala panda on 2023/05/12.
//

import UIKit

struct Todo: Identifiable {
    var id: UUID // Todo.ID が UUID のエイリアスになる
    var title: String
    var done: Bool
}
final class TodoRepository {


    private var todos: [Todo] = (1...30).map { i in
        Todo(id: UUID(), title: "Todo #\(i)", done: false)
    }
    var showsOnlyUndoneTodes: Bool = false

    func todo(id: Todo.ID) -> Todo? {
        todos.first(where: { $0.id == id })
    }

    func removeTodo(id: Todo.ID) {
        todos = todos.filter { $0.id != id }
    }

//    var todoIDs: [Todo.ID] { todos.map(\.id)}
    var todoIDs: [Todo.ID] { todos.filter { showsOnlyUndoneTodes ? !$0.done : true}.map(\.id)}

    func toggleTodo(id: Todo.ID) {
        for i in todos.indices {
            if todos[i].id == id {
                todos[i].done.toggle()
            }
        }
    }

    func toggleVisbility() {
        showsOnlyUndoneTodes.toggle()
    }


}

final class TodoListViewController: UIViewController {
    enum Section {
        case main
    }
    private var collectionView: UICollectionView!

    private var dataSource: UICollectionViewDiffableDataSource<Section, Todo.ID>!
    private var repository: TodoRepository = .init()



    override func viewDidLoad() {
        super.viewDidLoad()
        configueCollectionView()
        configureDataSource()
        applySnapshot()
        configureNavigationBar()

    }
    private func configueCollectionView() {
        // collection view を初期化
        let layout = UICollectionViewCompositionalLayout { sectionIndex, layoutEnvironment in
            var configuration = UICollectionLayoutListConfiguration(appearance: .plain)
            configuration.trailingSwipeActionsConfigurationProvider = { IndexPath in
                let deleteAction = UIContextualAction(style: .destructive, title: "削除") { [weak self] action, view, completion in
                    guard let self = self,
                          let todoID = self.dataSource.itemIdentifier(for: IndexPath)
                    else {
                        completion(false)
                        return
                    }
                    self.repository.removeTodo(id: todoID)
                    self.applySnapshot()
                    completion(true)

                }
                return UISwipeActionsConfiguration(actions: [deleteAction])
            }
            configuration.headerMode = .supplementary
            return NSCollectionLayoutSection.list(using: configuration, layoutEnvironment: layoutEnvironment)
        }
        collectionView = UICollectionView(frame: .null, collectionViewLayout: layout)
        collectionView.delegate = self


        // collection view を view の全面を覆う形で hierarchy に追加
        view.addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        collectionView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true

    }

    private func configureNavigationBar() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "line.3.horizontal.decrease"),
            primaryAction: UIAction { [weak self] _ in
                guard let self = self else { return }
                self.repository.toggleVisbility()
                self.applySnapshot()
            }
        )
    }

    private func configureDataSource() {
        let todoCellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, Todo> { cell, indexPath, todo in
            var configuration = cell.defaultContentConfiguration()
            configuration.text = todo.title
            cell.contentConfiguration = configuration

            cell.accessories = [
                .checkmark(displayed: .always, options: .init(isHidden: !todo.done))
            ]
        }
        // DataSource の生成
        self.dataSource = UICollectionViewDiffableDataSource(
            collectionView: self.collectionView, // DataSource と CollectionView の紐づけ
            cellProvider: { [weak self] collectionView, indexPath, todoID in // Cell を dequeue　して返却
                let todo = self?.repository.todo(id: todoID)
                return collectionView.dequeueConfiguredReusableCell(using: todoCellRegistration, for: indexPath, item: todo)
            }
        )

        let headerRegistration = UICollectionView.SupplementaryRegistration<UICollectionViewListCell>(elementKind: UICollectionView.elementKindSectionHeader) { view, elementKind, indexPath in
            var configuration = view.defaultContentConfiguration()
            configuration.text = "Todos"
            view.contentConfiguration = configuration
        }

        dataSource.supplementaryViewProvider = { collectionView, elementKind, indexPath in
            return collectionView.dequeueConfiguredReusableSupplementary(using: headerRegistration, for: indexPath)
        }
    }


    private func applySnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Todo.ID>()
        snapshot.appendSections([.main])
        snapshot.appendItems(repository.todoIDs, toSection: .main)
        dataSource.apply(snapshot, animatingDifferences: true)
    }

    private func applySnapshotByReconfiguringItem(todoID: Todo.ID) {
        var snapshot = dataSource.snapshot()
        snapshot.reconfigureItems([todoID])

        dataSource.apply(snapshot, animatingDifferences: true)
    }
}

extension TodoListViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        guard let todoID = self.dataSource.itemIdentifier(for: indexPath) else { return }
        repository.toggleTodo(id: todoID)
        applySnapshotByReconfiguringItem(todoID: todoID)

    }
}


