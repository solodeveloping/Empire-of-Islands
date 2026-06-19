class_name Rels

static var belongs_to: Relationship = Relationship.new(R_BelongsTo.new(), null)
static var going_to: Relationship = Relationship.new(R_GoingTo.new(), null)
static var works_at: Relationship = Relationship.new(R_WorksAt.new(), null)
static var travels_in: Relationship = Relationship.new(R_TravelsIn.new(), null)
static var lives_in: Relationship = Relationship.new(R_LivesIn.new(), null)

static func create_belongs_to(parent: Entity) -> Relationship:
	return Relationship.new(R_BelongsTo.new(), parent)
	
static func create_going_to(parent: Entity) -> Relationship:
	return Relationship.new(R_GoingTo.new(), parent)
	
static func create_works_at(parent: Entity) -> Relationship:
	return Relationship.new(R_WorksAt.new(), parent)

static func create_travels_in(parent: Entity) -> Relationship:
	return Relationship.new(R_TravelsIn.new(), parent)

static func create_lives_in(parent: Entity) -> Relationship:
	return Relationship.new(R_LivesIn.new(), parent)
