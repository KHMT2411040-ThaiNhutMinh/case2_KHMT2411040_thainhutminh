const statusLabels = {
  'todo': 'Chưa thực hiện',
  'in_progress': 'Đang thực hiện',
  'completed': 'Đã hoàn thành',
};

const priorityLabels = {
  'low': 'Thấp',
  'medium': 'Trung bình',
  'high': 'Cao',
};

const sortLabels = {
  'createdAt': 'Mới tạo nhất',
  'dueDate': 'Hạn gần nhất',
  'priority': 'Ưu tiên cao trước',
};

const roleLabels = {
  'owner': 'Người tạo',
  'editor': 'Được sửa',
  'assignee': 'Được giao',
  'viewer': 'Chỉ xem',
};

const permissionLabels = {
  'viewer': 'Chỉ xem',
  'editor': 'Chỉnh sửa',
};

// Bộ lọc theo vai trò ở danh sách (khớp ?role= của backend)
const roleFilterLabels = {
  'created': 'Của tôi',
  'assigned': 'Được giao',
  'shared': 'Được chia sẻ',
};