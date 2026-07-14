sealed class Failure { const Failure(this.message); final String message; }
class ValidationFailure extends Failure { const ValidationFailure(super.message); }
class DatabaseFailure extends Failure { const DatabaseFailure(super.message); }
class FileSystemFailure extends Failure { const FileSystemFailure(super.message); }
class PermissionFailure extends Failure { const PermissionFailure(super.message); }
class NotificationFailure extends Failure { const NotificationFailure(super.message); }
class EncryptionFailure extends Failure { const EncryptionFailure(super.message); }
class BackupFailure extends Failure { const BackupFailure(super.message); }
class RestoreFailure extends Failure { const RestoreFailure(super.message); }
class BiometricFailure extends Failure { const BiometricFailure(super.message); }
class UnknownFailure extends Failure { const UnknownFailure(super.message); }
