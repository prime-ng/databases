

(Note: MySQL itself handles database triggers rather than application-layer "Observers," but Laravel's Eloquent Observers map directly to database actions performed on MySQL tables.)

Available Observer Events in Laravel
1. **Retrieve Events**: Fired when fetching models
   - `retrieved` : Triggered after an existing model is retrieved from the database. (this may be more of an event that will be used in caching)
2. **Create Events**: Fired when creating models
   - `creating` :Triggered before a model is created/inserted into the database.
   - `created` : Triggered after a model is saved to the database for the first time.
   - `saved` (fired after both creating and updating)
3. **Update Events**: Fired when updating models
   - `updating` : Triggered before an existing model is updated.
   - `updated` : Triggered after changes to a model are saved to the database.
4. **Saved Events**: Triggered when a model is saving/saved
   - `saving` : Triggered before a model is saved (both creation and updating).
   - `saved` : Triggered after a model is saved (both creation and updating).
5. **Delete Events**: Fired when deleting models
   - `deleting` : Triggered before a model is deleted or soft-deleted.
   - `deleted` : Triggered after a model is deleted or soft-deleted.
6. **Force Delete Events**: Fired when permanently deleting models
   - `forceDeleting` : Triggered before a model is force-deleted.
   - `forceDeleted` : Triggered after a model is force-deleted.
7. **Soft Delete Events**: Triggered when a model is soft-deleted or restored (when using the SoftDeletes trait)
   - `trashed` : Triggered after a model is soft-deleted (when using the SoftDeletes trait).
   - `restoring` : Triggered before a soft-deleted model is restored.
   - `restored` : Triggered after a soft-deleted model is restored.
8. **Replicating Events**: Triggered when a model is being cloned or replicated using replicate()
   - `recreating` : Triggered before a model is replicated using replicate()
   - `recreated` : Triggered after a model is replicated using replicate()

---

