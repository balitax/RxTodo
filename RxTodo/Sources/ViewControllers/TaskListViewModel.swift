//
//  TaskListViewModel.swift
//  RxTodo
//
//  Created by Suyeol Jeon on 7/1/16.
//  Copyright © 2016 Suyeol Jeon. All rights reserved.
//

import RxCocoa
import RxDataSources
import RxSwift

typealias TaskListSection = SectionModel<Void, TaskCellModelType>

protocol TaskListViewModelType {

    // Input
    var addButtonDidTap: PublishSubject<Void> { get }
    var itemDidSelect: PublishSubject<NSIndexPath> { get }

    // Output
    var navigationBarTitle: Driver<String?> { get }
    var sections: Driver<[TaskListSection]> { get }
    var presentTaskEditViewModel: Driver<TaskEditViewModel> { get }

}

struct TaskListViewModel: TaskListViewModelType {

    // MARK: Input

    let addButtonDidTap = PublishSubject<Void>()
    let itemDidSelect = PublishSubject<NSIndexPath>()


    // MARK: Output

    let navigationBarTitle: Driver<String?>
    let sections: Driver<[TaskListSection]>
    let presentTaskEditViewModel: Driver<TaskEditViewModel>


    // MARK: Private

    private let disposeBag = DisposeBag()
    private var tasks: Variable<[Task]>

    init() {
        let tasks = Variable<[Task]>([])
        self.tasks = tasks
        self.navigationBarTitle = .just("Tasks")
        self.sections = tasks.asObservable()
            .map { tasks in
                let cellModels = tasks.map(TaskCellModel.init) as [TaskCellModelType]
                let section = TaskListSection(model: Void(), items: cellModels)
                return [section]
            }
            .asDriver(onErrorJustReturn: [])

        //
        // View Controller Navigations
        //
        let presentAddViewModel: Driver<TaskEditViewModel> = self.addButtonDidTap.asDriver()
            .map { TaskEditViewModel(mode: .New) }

        let presentEditViewModel: Driver<TaskEditViewModel> = self.itemDidSelect
            .map { indexPath in
                let task = tasks.value[indexPath.row]
                return TaskEditViewModel(mode: .Edit(task))
            }
            .asDriver(onErrorDriveWith: .never())

        self.presentTaskEditViewModel = Driver.of(presentAddViewModel, presentEditViewModel).merge()

        //
        // Model Service
        //
        Task.didCreate
            .subscribeNext { task in
                self.tasks.value.insert(task, atIndex: 0)
            }
            .addDisposableTo(self.disposeBag)

        Task.didUpdate
            .subscribeNext { task in
                if let index = self.tasks.value.indexOf(task) {
                    self.tasks.value[index] = task
                }
            }
            .addDisposableTo(self.disposeBag)

        Task.didDelete
            .subscribeNext { task in
                if let index = self.tasks.value.indexOf(task) {
                    self.tasks.value.removeAtIndex(index)
                }
            }
            .addDisposableTo(self.disposeBag)
    }

}
