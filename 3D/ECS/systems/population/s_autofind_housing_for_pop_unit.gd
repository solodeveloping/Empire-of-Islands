extends System
class_name AutofindHousingForPopUnitSystem

# WARN: we can't use this
# would run continuously as long as there are no changes
# better to react to changes

# This class automatically find vacant housing and assign it to a population unit

#func sub_systems():
	#return [
		#[
			#ECS.world.query.with_all([C_LookingForHousing,]),
			#find_housing
		#],
	#]
#
#func find_housing(entities: Array[Entity], _components: Array, delta: float):
	## WARN: we have to duplicate it 
	## otherwise we are modifying the ECS data directlly
	#var housing_buildings = ECS.world.query.with_all(
		#[C_HousingCapacity, C_NotFullyOccupied]
	#).enabled().execute().duplicate()
	#
	#for pop_unit in entities:
		#var c_pop_unit: C_PopUnit = pop_unit.get_component(C_PopUnit)
		#if !c_pop_unit:
			#push_error("c_pop_unit is not present")
			#return
		#
		##var found_housing: bool = false
		#for housing: Entity in housing_buildings:
			#var c_housing_capacity: C_HousingCapacity = housing.get_component(C_HousingCapacity)
			#if !c_housing_capacity:
				#push_error("c_housing_capacity is not present")
				#continue
			#if c_housing_capacity.current >= c_housing_capacity.maximum:
				##push_error("c_housing_capacity.current %s >= c_housing_capacity.maximum %s" % [
					##c_housing_capacity.current,
					##c_housing_capacity.maximum,
				##])
				#housing_buildings.erase(housing)
				#continue
				#
			#if c_housing_capacity.pop_type != c_pop_unit.pop_type:
				#print("wrong pop_type %s %s" % [
					#c_housing_capacity.pop_type,
					#c_pop_unit.pop_type,
				#])
				#continue
				#
			##found_housing = true
			##print("increasing capacity of %s"% [
				##housing.get_path(),
			##])
			#c_housing_capacity.current += 1
			#if c_housing_capacity.current >= c_housing_capacity.maximum:
				#cmd.remove_component(housing, C_NotFullyOccupied)
				#housing_buildings.erase(housing)
			#
			#cmd.add_relationship(pop_unit, Rels.create_lives_in(housing))
			#
			## WARN: important to stop looping once we found a housing
			#break
		#
		##if !found_housing:
			##cmd.add_component(entity, C_LookingForHousing.new())
