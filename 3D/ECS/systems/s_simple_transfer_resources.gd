class_name SimpleTransferResourcesSystem
extends System

@export
var storage: Node

func sub_systems():
	return [
		[
			ECS.world.query.with_all([C_AwaitingResources]),
			transfer_resources
		],
	]

func transfer_resources(entities: Array[Entity], _components: Array, _delta: float):
	for entity in entities:
		var c_requirement: C_ResourceRequirement = entity.get_component(C_ResourceRequirement)
		if !c_requirement:
			push_error("entity has C_AwaitingResources but not C_ResourceRequirement")
			continue
		
		var c_stored_resources: C_BuildingStoredResources = entity.get_component(C_BuildingStoredResources)
		if !c_stored_resources:
			c_stored_resources = C_BuildingStoredResources.new({})
			entity.add_component(c_stored_resources)
		
		var c_needed_resources: C_NeededResources = entity.get_component(C_NeededResources)
		if !c_needed_resources:
			c_needed_resources = C_NeededResources.new([])
			
			for req in c_requirement.requirements:
				var req_ = req.duplicate()
				
				# Try to fit the requirements immediatly
				var stored: Resource_Stack = c_stored_resources.stacks.get(
					req.resource_type
				)
				if !stored:
					stored = Resource_Stack.new()
					stored.resource_type = req.resource_type
					stored.resource_count = 0
					c_stored_resources.stacks.set(req.resource_type, stored)
				
				var quantity = req.resource_count - stored.resource_count	
				var result = storage.take_as_much_as_possible(
					req.resource_type,
					quantity
				)
				if result.successful:
					stored.resource_count += result.quantity_taken
					if stored.resource_count == req.resource_count:
						continue
					else:
						req_.resource_count -= result.quantity_taken
						
						c_needed_resources.needs.push_back(req_)
				else:
					c_needed_resources.needs.push_back(req_)
		
			if c_needed_resources.needs.size() > 0:
				cmd.add_component(entity, c_needed_resources)
			else:
				cmd.remove_component(entity, C_AwaitingResources)
		else:
			var completed_needs: Array[Resource_Requirement] = []
			for need in c_needed_resources.needs:
				var stored: Resource_Stack = c_stored_resources.stacks.get(
					need.resource_type
				)
				if !stored:
					stored = Resource_Stack.new()
					stored.resource_type = need.resource_type
					stored.resource_count = 0
					c_stored_resources.stacks.set(need.resource_type, stored)
				
				var quantity = need.resource_count - stored.resource_count	
				var result = storage.take_as_much_as_possible(
					need.resource_type,
					quantity
				)
				if result.successful:
					stored.resource_count += result.quantity_taken
					need.resource_count -= result.quantity_taken
					
					if stored.resource_count == need.resource_count:
						completed_needs.push_back(need)
				else:
					pass
			
			for need in completed_needs:
				c_needed_resources.needs.erase(need)
			
			if c_needed_resources.needs.size() == 0:
				# FIXME: could keep it?
				cmd.remove_component(entity, C_NeededResources)
				
				# but not this one
				cmd.remove_component(entity, C_AwaitingResources)
				cmd.add_component(entity, C_HasResources.new())
		
