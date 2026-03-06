import '../../core/error/result.dart';

/// Base repository interface
/// Defines common CRUD operations for all repositories.
/// Generic type T represents the entity type, ID represents the identifier type.
/// All methods return Result<T> to handle errors functionally.
abstract class Repository<T, ID> {
  /// Get entity by ID
  Future<Result<T>> getById(ID id);

  /// Get all entities
  Future<Result<List<T>>> getAll();

  /// Create new entity
  Future<Result<T>> create(T entity);

  /// Update existing entity
  Future<Result<T>> update(T entity);

  /// Delete entity by ID
  Future<Result<void>> delete(ID id);
}
