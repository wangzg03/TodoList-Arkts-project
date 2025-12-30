// 定义接口
interface StorageKeysType {
  TODOS: string;
  HEALTH_ITEMS: string;
  HEALTH_STREAK_DAYS: string;
  LAST_RESET_DATE: string;
  HAS_COMPLETED_TODAY: string;
  NEXT_ID: string;
}

// 定义存储键
const StorageKeys: StorageKeysType = {
  TODOS: 'todos',
  HEALTH_ITEMS: 'healthReminderItems',
  HEALTH_STREAK_DAYS: 'healthStreakDays',
  LAST_RESET_DATE: 'lastResetDate',
  HAS_COMPLETED_TODAY: 'hasCompletedToday',
  NEXT_ID: 'nextId',
};

// 定义任务结构
interface TodoItem {
  id: number;
  text: string;
  completed: boolean;
  priority: number;
  order: number;
  createdAt: number;
  completedAt: number;
}

interface HealthReminderItem {
  id: number;
  name: string;
  description: string;
  selected: boolean;
  uiSelected: boolean;
}

@Entry
@Component
struct TodoListApp {
  // 使用LocalStorageLink连接存储
  @LocalStorageLink(StorageKeys.TODOS) todos: TodoItem[] = [];
  @LocalStorageLink(StorageKeys.HEALTH_ITEMS) healthReminderItems: HealthReminderItem[] = [];
  @LocalStorageLink(StorageKeys.HEALTH_STREAK_DAYS) healthStreakDays: number = 0;
  @LocalStorageLink(StorageKeys.LAST_RESET_DATE) lastResetDate: number = 0;
  @LocalStorageLink(StorageKeys.HAS_COMPLETED_TODAY) hasCompletedToday: boolean = false;
  @LocalStorageLink(StorageKeys.NEXT_ID) nextId: number = 4;

  // 非持久化状态
  @State newTodoText: string = '';
  @State newTodoPriority: number = 2;
  @State draggingIndex: number = -1;
  @State hoverIndex: number = -1;
  @State currentView: 'all' | 'completed' | 'uncompleted' = 'all';
  @State healthSuccessMessage: string = '';
  @State motivationalMessages: string[] = [
    '设定目标，追逐梦想！',
    '每天进步一点点！',
    '你比自己想象的更强大！',
    '今天的努力是明天的收获！',
    '坚持就是胜利！',
    '让今天的你比昨天更好！',
    '小步快跑，持续进步！',
    '成长从行动开始！',
    '每一次尝试都值得骄傲！',
    '相信自己，你能做到！',
    '成功属于坚持不懈的人！',
    '梦想在前方等你！'
  ];
  @State emptyStateMotivation: string = '';
  @State healthForceUpdateKey: number = 0;
  @State todosForceUpdateKey: number = 0;
  private healthResetTimer: number = 0;
  private storage: LocalStorage = new LocalStorage();

  getPriorityColor(priority: number): string {
    switch (priority) {
      case 1: return '#FF6B6B';
      case 2: return '#FFA726';
      case 3: return '#4CAF50';
      default: return '#757575';
    }
  }

  getPriorityText(priority: number): string {
    switch (priority) {
      case 1: return '高';
      case 2: return '中';
      case 3: return '低';
      default: return '中';
    }
  }

  getImageResource(name: string): Resource {
    switch (name) {
      case '喝水': return $r('app.media.water');
      case '运动': return $r('app.media.sports');
      case '饮食': return $r('app.media.eat');
      case '休息': return $r('app.media.sleep');
      case '学习': return $r('app.media.study');
      default: return $r('app.media.water');
    }
  }

  addTodo(): void {
    const trimmedText = this.newTodoText.trim();
    if (trimmedText === '') return;

    const newTodo: TodoItem = {
      id: this.nextId,
      text: trimmedText,
      completed: false,
      priority: this.newTodoPriority,
      order: this.todos.length + 1,
      createdAt: Date.now(),
      completedAt: 0
    };

    this.todos.push(newTodo);
    this.nextId = this.nextId + 1;
    this.newTodoText = '';
    this.sortTodos();
    this.todosForceUpdateKey = this.todosForceUpdateKey + 1;
  }

  deleteTodo(id: number): void {
    const newTodos: TodoItem[] = [];
    for (let i = 0; i < this.todos.length; i++) {
      if (this.todos[i].id !== id) {
        newTodos.push(this.todos[i]);
      }
    }
    this.todos = newTodos;
    this.reorderTodos();
    this.todosForceUpdateKey = this.todosForceUpdateKey + 1;
  }

  toggleComplete(id: number): void {
    const newTodos: TodoItem[] = [];
    for (let i = 0; i < this.todos.length; i++) {
      if (this.todos[i].id === id) {
        const isNowCompleted = !this.todos[i].completed;
        const updatedTodo: TodoItem = {
          id: this.todos[i].id,
          text: this.todos[i].text,
          completed: isNowCompleted,
          priority: this.todos[i].priority,
          order: this.todos[i].order,
          createdAt: this.todos[i].createdAt,
          completedAt: isNowCompleted ? Date.now() : 0
        };
        newTodos.push(updatedTodo);
      } else {
        newTodos.push(this.todos[i]);
      }
    }
    this.todos = newTodos;
    this.sortTodos();
    this.todosForceUpdateKey = this.todosForceUpdateKey + 1;
  }

  toggleHealthReminderItem(index: number): void {
    console.log(`=== 真正分离策略 ===`);

    const newHealthItems: HealthReminderItem[] = [];
    for (let i = 0; i < this.healthReminderItems.length; i++) {
      if (i === index) {
        const newItem: HealthReminderItem = {
          id: this.healthReminderItems[i].id,
          name: this.healthReminderItems[i].name,
          description: this.healthReminderItems[i].description,
          selected: !this.healthReminderItems[i].selected,
          uiSelected: this.healthReminderItems[i].uiSelected
        };
        newHealthItems.push(newItem);
      } else {
        const sameItem: HealthReminderItem = {
          id: this.healthReminderItems[i].id,
          name: this.healthReminderItems[i].name,
          description: this.healthReminderItems[i].description,
          selected: this.healthReminderItems[i].selected,
          uiSelected: this.healthReminderItems[i].uiSelected
        };
        newHealthItems.push(sameItem);
      }
    }
    this.healthReminderItems = newHealthItems;

    setTimeout(() => {
      this.healthReminderItems[index].uiSelected = !this.healthReminderItems[index].uiSelected;
      this.healthForceUpdateKey = this.healthForceUpdateKey + 1;
      console.log(`UI状态已更新: ${this.healthReminderItems[index].name} = ${this.healthReminderItems[index].uiSelected}`);
    }, 10);

    this.checkAllHealthGoalsCompleted();
  }

  toggleAllHealthReminders(): void {
    console.log('=== 一键切换 - 真正分离策略 ===');

    let allSelected = true;
    for (let i = 0; i < this.healthReminderItems.length; i++) {
      if (!this.healthReminderItems[i].selected) {
        allSelected = false;
        break;
      }
    }

    const newHealthItems: HealthReminderItem[] = [];
    for (let i = 0; i < this.healthReminderItems.length; i++) {
      const newItem: HealthReminderItem = {
        id: this.healthReminderItems[i].id,
        name: this.healthReminderItems[i].name,
        description: this.healthReminderItems[i].description,
        selected: !allSelected,
        uiSelected: this.healthReminderItems[i].uiSelected
      };
      newHealthItems.push(newItem);
    }
    this.healthReminderItems = newHealthItems;

    setTimeout(() => {
      for (let i = 0; i < this.healthReminderItems.length; i++) {
        this.healthReminderItems[i].uiSelected = !allSelected;
      }
      this.healthForceUpdateKey = this.healthForceUpdateKey + 1;
      console.log('所有UI状态已更新');
    }, 10);

    this.checkAllHealthGoalsCompleted();
  }

  checkAllHealthGoalsCompleted(): void {
    let allCompleted = true;
    let completedCount = 0;

    for (let i = 0; i < this.healthReminderItems.length; i++) {
      if (this.healthReminderItems[i].selected) {
        completedCount = completedCount + 1;
      } else {
        allCompleted = false;
      }
    }

    const today = new Date().setHours(0, 0, 0, 0);

    if (allCompleted) {
      if (!this.hasCompletedToday && this.lastResetDate === today) {
        this.healthStreakDays = this.healthStreakDays + 1;
        this.hasCompletedToday = true;
        this.healthSuccessMessage = `太棒了！你已经连续健康生活${this.healthStreakDays}天了！`;
      } else if (this.hasCompletedToday) {
        this.healthSuccessMessage = '今日已完成健康打卡！';
      }

      setTimeout(() => {
        this.healthSuccessMessage = '';
      }, 3000);
    }
  }

  resetHealthGoals(): void {
    const today = new Date().setHours(0, 0, 0, 0);

    if (this.lastResetDate < today) {
      const newItems: HealthReminderItem[] = [];
      for (let i = 0; i < this.healthReminderItems.length; i++) {
        const newItem: HealthReminderItem = {
          id: this.healthReminderItems[i].id,
          name: this.healthReminderItems[i].name,
          description: this.healthReminderItems[i].description,
          selected: false,
          uiSelected: false
        };
        newItems.push(newItem);
      }

      this.healthReminderItems = newItems;
      this.lastResetDate = today;
      this.hasCompletedToday = false;
      this.healthForceUpdateKey = this.healthForceUpdateKey + 1;

      if (this.healthResetTimer) {
        clearTimeout(this.healthResetTimer);
      }
      this.setupHealthResetTimer();
    }
  }

  setupHealthResetTimer(): void {
    const now = new Date();
    const tomorrow = new Date(now.getFullYear(), now.getMonth(), now.getDate() + 1);
    const timeUntilMidnight = tomorrow.getTime() - now.getTime();

    this.healthResetTimer = setTimeout(() => {
      this.resetHealthGoals();
    }, timeUntilMidnight);
  }

  reorderTodos(): void {
    const reorderedTodos: TodoItem[] = [];
    for (let i = 0; i < this.todos.length; i++) {
      const reorderedTodo: TodoItem = {
        id: this.todos[i].id,
        text: this.todos[i].text,
        completed: this.todos[i].completed,
        priority: this.todos[i].priority,
        order: i + 1,
        createdAt: this.todos[i].createdAt,
        completedAt: this.todos[i].completedAt
      };
      reorderedTodos.push(reorderedTodo);
    }
    this.todos = reorderedTodos;
  }

  sortTodos(): void {
    this.todos.sort((a: TodoItem, b: TodoItem) => {
      if (a.completed && !b.completed) return 1;
      if (!a.completed && b.completed) return -1;

      if (!a.completed && !b.completed) {
        if (a.priority !== b.priority) return a.priority - b.priority;
        return a.createdAt - b.createdAt;
      }

      if (a.completed && b.completed) {
        if (a.priority !== b.priority) return a.priority - b.priority;
        return b.completedAt - a.completedAt;
      }

      return 0;
    });
    this.reorderTodos();
  }

  handleDragStart(index: number): void {
    this.draggingIndex = index;
  }

  handleDragEnter(index: number): void {
    if (this.draggingIndex !== -1 && this.draggingIndex !== index) {
      this.hoverIndex = index;
    }
  }

  handleDragLeave(): void {
    this.hoverIndex = -1;
  }

  handleDragEnd(): void {
    if (this.draggingIndex !== -1 && this.hoverIndex !== -1) {
      const dragged = this.todos.splice(this.draggingIndex, 1)[0];
      this.todos.splice(this.hoverIndex, 0, dragged);
      this.reorderTodos();
      this.todosForceUpdateKey = this.todosForceUpdateKey + 1;
    }
    this.draggingIndex = -1;
    this.hoverIndex = -1;
  }

  getCompletedHealthCount(): number {
    let count = 0;
    for (let i = 0; i < this.healthReminderItems.length; i++) {
      if (this.healthReminderItems[i].selected) {
        count = count + 1;
      }
    }
    return count;
  }

  getDisplayedTodos(): TodoItem[] {
    switch (this.currentView) {
      case 'completed':
        const completedTodos: TodoItem[] = [];
        for (let i = 0; i < this.todos.length; i++) {
          if (this.todos[i].completed) {
            completedTodos.push(this.todos[i]);
          }
        }
        return completedTodos;
      case 'uncompleted':
        const uncompletedTodos: TodoItem[] = [];
        for (let i = 0; i < this.todos.length; i++) {
          if (!this.todos[i].completed) {
            uncompletedTodos.push(this.todos[i]);
          }
        }
        return uncompletedTodos;
      default:
        return this.todos;
    }
  }

  getCompletedCount(): number {
    let count = 0;
    for (let i = 0; i < this.todos.length; i++) {
      if (this.todos[i].completed) {
        count = count + 1;
      }
    }
    return count;
  }

  getUncompletedCount(): number {
    let count = 0;
    for (let i = 0; i < this.todos.length; i++) {
      if (!this.todos[i].completed) {
        count = count + 1;
      }
    }
    return count;
  }

  getRandomMotivationalMessage(): string {
    const randomIndex = Math.floor(Math.random() * this.motivationalMessages.length);
    return this.motivationalMessages[randomIndex];
  }

  getMotivationalMessage(): string {
    const completed = this.getCompletedCount();
    const total = this.todos.length;

    if (total === 0) return '开始你的第一个任务吧！';
    if (completed === total) return '太棒了！所有任务都完成了！';

    const percentage = (completed / total) * 100;
    if (percentage >= 80) return this.getRandomMotivationalMessage();
    if (percentage >= 50) return '已经完成一半了，继续努力！';
    if (percentage >= 20) return '良好的开始，坚持下去！';
    return '迈出第一步很重要，加油！';
  }

  setEmptyStateMotivation(): void {
    if (this.currentView === 'uncompleted' && this.getUncompletedCount() === 0) {
      this.emptyStateMotivation = '太棒了！所有任务都已完成，继续保持这种专注力！';
    } else if (this.currentView === 'completed' && this.getCompletedCount() === 0) {
      this.emptyStateMotivation = '开始行动吧！每完成一个小任务都是向目标迈进的一步！';
    } else {
      this.emptyStateMotivation = this.getRandomMotivationalMessage();
    }
  }

  aboutToAppear() {
    this.initializePersistentStorage();
    this.resetHealthGoals();
    this.setupHealthResetTimer();
  }

  aboutToDisappear() {
    if (this.healthResetTimer) {
      clearTimeout(this.healthResetTimer);
    }
  }

  // 初始化持久化存储
  private initializePersistentStorage(): void {
    console.log('=== 初始化持久化存储 ===');

    // 如果存储中还没有数据，设置默认值
    if (this.todos.length === 0) {
      const defaultTodos: TodoItem[] = [
        {
          id: 1,
          text: '完成项目报告',
          completed: false,
          priority: 1,
          order: 1,
          createdAt: Date.now() - 86400000,
          completedAt: 0
        },
        {
          id: 2,
          text: '购买生活用品',
          completed: false,
          priority: 2,
          order: 2,
          createdAt: Date.now() - 43200000,
          completedAt: 0
        },
        {
          id: 3,
          text: '阅读30分钟',
          completed: true,
          priority: 3,
          order: 3,
          createdAt: Date.now() - 21600000,
          completedAt: Date.now() - 10800000
        }
      ];
      this.todos = defaultTodos;
    }

    if (this.healthReminderItems.length === 0) {
      const defaultHealthItems: HealthReminderItem[] = [
        { id: 1, name: '喝水', description: '每天8杯水', selected: false, uiSelected: false },
        { id: 2, name: '运动', description: '运动起来', selected: false, uiSelected: false },
        { id: 3, name: '饮食', description: '均衡饮食', selected: false, uiSelected: false },
        { id: 4, name: '休息', description: '充足睡眠', selected: false, uiSelected: false },
        { id: 5, name: '学习', description: '学习1小时', selected: false, uiSelected: false }
      ];
      this.healthReminderItems = defaultHealthItems;
    }

    console.log('持久化存储初始化完成');
  }

  build() {
    Column({ space: 20 }) {
      // 健康目标区域
      Column({ space: 15 }) {
        Row({ space: 10 }) {
          Text('今日健康目标')
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor('#333')

          Text(`(${this.getCompletedHealthCount()}/${this.healthReminderItems.length})`)
            .fontSize(16)
            .fontColor('#666')
        }
        .width('100%')
        .justifyContent(FlexAlign.Start)
        .padding({ left: 20 })

        if (this.healthSuccessMessage !== '') {
          Text(this.healthSuccessMessage)
            .fontSize(16)
            .fontColor('#4CAF50')
            .margin({ top: 5, bottom: 5 })
            .width('100%')
            .textAlign(TextAlign.Center)
        }

        Row({ space: 10 }) {
          Button('一键完成')
            .width(120)
            .height(40)
            .fontColor(Color.White)
            .backgroundColor('#2196F3')
            .onClick(() => {
              this.toggleAllHealthReminders();
            })
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .margin({ bottom: 10 })

        // 健康目标列表
        Scroll() {
          Row({ space: 15 }) {
            ForEach(
              this.healthReminderItems,
              (reminder: HealthReminderItem, index: number) => {
                Column({ space: 8 }) {
                  Column() {
                    Image(this.getImageResource(reminder.name))
                      .width(35)
                      .height(35)
                      .objectFit(ImageFit.Contain)
                      .opacity(reminder.uiSelected ? 1.0 : 0.6)
                  }
                  .width(40)
                  .height(40)
                  .backgroundColor(reminder.uiSelected ? '#4CAF50' : '#E0E0E0')
                  .borderRadius(22.5)
                  .margin({ bottom: 3 })

                  Circle({ width: 8, height: 8 })
                    .fill(reminder.uiSelected ? '#4CAF50' : '#FF9800')
                    .margin({ bottom: 3 })

                  Button(reminder.uiSelected ? '已完成' : '未完成')
                    .width(75)
                    .height(30)
                    .fontSize(11)
                    .fontColor(Color.White)
                    .backgroundColor(reminder.uiSelected ? '#4CAF50' : '#FF9800')
                    .onClick(() => {
                      this.toggleHealthReminderItem(index);
                    })

                  Text(reminder.name)
                    .fontSize(13)
                    .fontColor('#333')
                    .fontWeight(FontWeight.Medium)
                    .maxLines(1)

                  Text(reminder.description)
                    .fontSize(10)
                    .fontColor('#999')
                    .maxLines(1)

                  if (reminder.uiSelected) {
                    Text('已完成')
                      .fontSize(9)
                      .fontColor('#4CAF50')
                      .fontWeight(FontWeight.Bold)
                      .backgroundColor('#E8F5E8')
                      .padding({ left: 4, right: 4, top: 1, bottom: 1 })
                      .borderRadius(3)
                      .margin({ top: 2 })
                  } else {
                    Text('未完成')
                      .fontSize(9)
                      .fontColor('#FF9800')
                      .fontWeight(FontWeight.Bold)
                      .backgroundColor('#FFF3E0')
                      .padding({ left: 4, right: 4, top: 1, bottom: 1 })
                      .borderRadius(3)
                      .margin({ top: 2 })
                  }
                }
                .width(85)
                .height(150)
                .padding(8)
                .backgroundColor(reminder.uiSelected ? '#E8F5E8' : '#FFFFFF')
                .borderRadius(12)
                .shadow({ radius: 2, color: reminder.uiSelected ? '#4CAF50' : '#DDD', offsetX: 0, offsetY: 1 })
              },
              (reminder: HealthReminderItem) => `${reminder.id}_${this.healthForceUpdateKey}`
            )
          }
          .padding({ left: 20, right: 20 })
        }
        .scrollable(ScrollDirection.Horizontal)
        .height(170)
      }
      .width('100%')
      .padding({ top: 15, bottom: 15 })
      .backgroundColor('#FFFFFF')
      .borderRadius(20)
      .margin({ left: 15, right: 15 })

      // 待办事项区域
      Column({ space: 15 }) {
        Row({ space: 10 }) {
          Text('我的待办事项')
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor('#333')

          Text(this.getMotivationalMessage())
            .fontSize(14)
            .fontColor('#FF6B6B')
            .layoutWeight(1)
            .textAlign(TextAlign.End)
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)

        Column({ space: 10 }) {
          Row({ space: 10 }) {
            TextInput({ text: this.newTodoText, placeholder: '输入新任务...' })
              .onChange((value: string) => {
                this.newTodoText = value;
              })
              .layoutWeight(1)
              .height(45)
              .backgroundColor(Color.White)
              .borderRadius(10)
              .padding(10)

            Button('添加')
              .width(80)
              .height(45)
              .fontColor(Color.White)
              .backgroundColor('#ff395fc1')
              .onClick(() => {
                this.addTodo();
              })
          }

          Row({ space: 10 }) {
            Text('优先级:')
              .fontSize(16)
              .fontColor('#666')

            ForEach(
              [1, 2, 3],
              (priority: number) => {
                Button(this.getPriorityText(priority))
                  .width(60)
                  .height(35)
                  .fontSize(14)
                  .backgroundColor(this.newTodoPriority === priority ? this.getPriorityColor(priority) : '#F0F0F0')
                  .fontColor(this.newTodoPriority === priority ? Color.White : '#666')
                  .onClick(() => {
                    this.newTodoPriority = priority;
                  })
              },
              (priority: number) => priority.toString()
            )
          }
        }
        .padding(15)
        .backgroundColor('#F8F9FA')
        .borderRadius(12)

        Row({ space: 10 }) {
          Button('总任务')
            .layoutWeight(1)
            .height(40)
            .backgroundColor(this.currentView === 'all' ? '#2196F3' : '#F0F0F0')
            .fontColor(this.currentView === 'all' ? Color.White : '#666')
            .onClick(() => {
              this.currentView = 'all';
              this.sortTodos();
              this.todosForceUpdateKey = this.todosForceUpdateKey + 1;
            })

          Button(`未完成 (${this.getUncompletedCount()})`)
            .layoutWeight(1)
            .height(40)
            .backgroundColor(this.currentView === 'uncompleted' ? '#4CAF50' : '#F0F0F0')
            .fontColor(this.currentView === 'uncompleted' ? Color.White : '#666')
            .onClick(() => {
              this.currentView = 'uncompleted';
              this.sortTodos();
              this.setEmptyStateMotivation();
              this.todosForceUpdateKey = this.todosForceUpdateKey + 1;
            })

          Button(`已完成 (${this.getCompletedCount()})`)
            .layoutWeight(1)
            .height(40)
            .backgroundColor(this.currentView === 'completed' ? '#FFA726' : '#F0F0F0')
            .fontColor(this.currentView === 'completed' ? Color.White : '#666')
            .onClick(() => {
              this.currentView = 'completed';
              this.sortTodos();
              this.setEmptyStateMotivation();
              this.todosForceUpdateKey = this.todosForceUpdateKey + 1;
            })
        }

        if (this.getDisplayedTodos().length === 0) {
          Column() {
            if (this.currentView === 'all') {
              Column() {
                Text('📄').fontSize(60)
              }
              .width(120)
              .height(120)
              .justifyContent(FlexAlign.Center)
              .alignItems(HorizontalAlign.Center)
              .margin({ bottom: 20 })
              Text('暂无待办事项').fontSize(18).fontColor('#999')
              Text('添加你的第一个任务吧！').fontSize(14).fontColor('#CCC').margin({ top: 5 })
              Text(this.getRandomMotivationalMessage())
                .fontSize(14)
                .fontColor('#FF6B6B')
                .margin({ top: 10 })
            } else if (this.currentView === 'uncompleted') {
              Column() {
                Column() {
                  Column() {
                    Text('🎉').fontSize(60)
                  }
                  .width(120)
                  .height(120)
                  .justifyContent(FlexAlign.Center)
                  .alignItems(HorizontalAlign.Center)
                  .margin({ bottom: 20 })

                  Text('暂无未完成任务').fontSize(18).fontColor('#4CAF50')
                  Text('太棒了！所有任务都完成了！').fontSize(14).fontColor('#999').margin({ top: 5 })
                }
                .layoutWeight(1)
                .justifyContent(FlexAlign.Center)
                .alignItems(HorizontalAlign.Center)

                Column() {
                  Blank().height(20)
                  Text(this.emptyStateMotivation || '太棒了！所有任务都已完成，继续保持这种专注力！')
                    .fontSize(16)
                    .fontColor('#4CAF50')
                    .fontWeight(FontWeight.Medium)
                    .textAlign(TextAlign.Center)
                    .width('100%')
                }
                .width('100%')
                .alignItems(HorizontalAlign.Center)
              }
              .width('100%')
              .flexGrow(1)
              .justifyContent(FlexAlign.SpaceBetween)

            } else {
              Column() {
                Column() {
                  Column() {
                    Text('📋').fontSize(60)
                  }
                  .width(120)
                  .height(120)
                  .justifyContent(FlexAlign.Center)
                  .alignItems(HorizontalAlign.Center)
                  .margin({ bottom: 20 })

                  Text('暂无已完成任务').fontSize(18).fontColor('#999')
                  Text('开始完成任务吧！').fontSize(14).fontColor('#CCC').margin({ top: 5 })
                }
                .layoutWeight(1)
                .justifyContent(FlexAlign.Center)
                .alignItems(HorizontalAlign.Center)

                Column() {
                  Blank().height(20)
                  Text(this.emptyStateMotivation || '开始行动吧！每完成一个小任务都是向目标迈进的一步！')
                    .fontSize(16)
                    .fontColor('#FF6B6B')
                    .fontWeight(FontWeight.Medium)
                    .textAlign(TextAlign.Center)
                    .width('100%')
                }
                .width('100%')
                .alignItems(HorizontalAlign.Center)
              }
              .width('100%')
              .flexGrow(1)
              .justifyContent(FlexAlign.SpaceBetween)
            }
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.SpaceBetween)
        } else {
          Scroll() {
            Column({ space: 10 }) {
              ForEach(
                this.getDisplayedTodos(),
                (item: TodoItem) => {
                  Column() {
                    Row({ space: 12 }) {
                      Column() {
                        Text('⋮⋮').fontSize(16).fontColor('#CCC').opacity(0.7)
                      }
                      .width(30)
                      .height('100%')
                      .justifyContent(FlexAlign.Center)
                      .onTouch((event: TouchEvent) => {
                        const realIndex = this.todos.findIndex(t => t.id === item.id);
                        if (event.type === TouchType.Down) this.handleDragStart(realIndex);
                        if (event.type === TouchType.Up) this.handleDragEnd();
                      })

                      Column() {
                        Image(item.completed ? $r('app.media.complete') : $r('app.media.empty'))
                          .width(20)
                          .height(20)
                      }
                      .width(30)
                      .height(30)
                      .justifyContent(FlexAlign.Center)
                      .alignItems(HorizontalAlign.Center)
                      .onClick(() => {
                        this.toggleComplete(item.id);
                      })

                      Column({ space: 4 }) {
                        Text(item.text)
                          .fontSize(16)
                          .fontColor(item.completed ? '#AAA' : '#333')
                          .decoration({
                            type: item.completed ? TextDecorationType.LineThrough : TextDecorationType.None
                          })

                        Row({ space: 4 }) {
                          Circle({ width: 8, height: 8 }).fill(this.getPriorityColor(item.priority))
                          Text(this.getPriorityText(item.priority) + '优先级')
                            .fontSize(12)
                            .fontColor(this.getPriorityColor(item.priority))
                        }
                      }
                      .layoutWeight(1)

                      Stack() {
                        Column()
                          .width(30)
                          .height(30)
                          .backgroundColor('#FF6B6B')
                          .borderRadius(5)

                        Text('×')
                          .fontSize(20)
                          .fontColor(Color.White)
                          .fontWeight(FontWeight.Bold)
                          .width('100%')
                          .height('100%')
                          .textAlign(TextAlign.Center)
                      }
                      .width(30)
                      .height(30)
                      .onClick(() => this.deleteTodo(item.id))
                    }
                    .width('100%')
                    .height(70)
                    .padding({ left: 10, right: 10 })
                    .backgroundColor(Color.White)
                    .borderRadius(10)
                    .shadow({ radius: 2, color: '#EEE', offsetX: 0, offsetY: 2 })
                    .onTouch((event: TouchEvent) => {
                      const realIndex = this.todos.findIndex(t => t.id === item.id);
                      if (event.type === TouchType.Move) this.handleDragEnter(realIndex);
                      if (event.type === TouchType.Up) this.handleDragLeave();
                    })
                  }
                  .margin({ bottom: 10 })
                  .border({
                    width: this.hoverIndex === this.todos.findIndex(t => t.id === item.id) ? 2 : 0,
                    color: '#2196F3',
                    style: BorderStyle.Dashed
                  })
                  .borderRadius(10)
                },
                (item: TodoItem) => `${item.id}_${this.todosForceUpdateKey}`
              )
            }
            .padding(10)
          }
          .scrollable(ScrollDirection.Vertical)
          .layoutWeight(1)
        }
      }
      .layoutWeight(1)
      .padding(20)
      .backgroundColor('#FFFFFF')
      .borderRadius({ topLeft: 20, topRight: 20 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F0F2F5')
  }
}
