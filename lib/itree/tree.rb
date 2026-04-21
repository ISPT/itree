module Intervals
	class Tree
		attr_accessor :root, :size

		# Sentinel used by #remove to distinguish "no data argument" from
		# data == nil (nil is a valid stored value).
		UNSET = Object.new.freeze
		private_constant :UNSET

		def initialize
			@root = nil
			@size = 0
		end

		def insert(leftScore, rightScore, data=nil, updateData=false)
			node = Node.new(leftScore,rightScore,data)
			success = true

			if @root.nil?
				@root = node
			else
				balance,success = insertNode(@root,node,updateData)
			end

			@size = @size + 1 if success
			return success
		end

		def insert!(leftScore, rightScore, data=nil)
			return insert(leftScore,rightScore,data,true)
		end

		def stab(minScore,maxScore=nil)
			maxScore = minScore if maxScore.nil?
			results = []
			stabNode(@root,minScore,maxScore,results) if @root
			results
		end

		def remove(leftScore, rightScore, data = UNSET)
			return false if @root.nil?

			target = findNode(leftScore, rightScore)
			return false unless target

			if data.equal?(UNSET)
				bucketSize = target.data_list.length
				delNode = Node.new(leftScore, rightScore, nil)
				_, removed = removeNode(@root, delNode)
				if removed
					@size -= bucketSize
					@root = nil if @size == 0
					return true
				end
				return false
			end

			idx = target.data_list.index(data)
			return false unless idx

			if target.data_list.length == 1
				delNode = Node.new(leftScore, rightScore, nil)
				_, removed = removeNode(@root, delNode)
				if removed
					@size -= 1
					@root = nil if @size == 0
					return true
				end
				return false
			end

			target.data_list.delete_at(idx)
			target.data = target.data_list.first if idx == 0
			@size -= 1
			true
		end

		private

		def findNode(leftScore, rightScore)
			search = Node.new(leftScore, rightScore, nil)
			node = @root
			while node
				diff = node <=> search
				return node if diff == 0
				node = diff > 0 ? node.left : node.right
			end
			nil
		end

		def insertNode(locNode,insertNode,updateData=false)
			diff = locNode <=> insertNode

			if diff > 0
				if locNode.left.nil?
					locNode.left = insertNode
					insertNode.parent = locNode
					locNode.balance = locNode.balance - 1
					locNode.updateMaxScores
					if locNode.balance == 0
						return 0,true
					else
						return 1,true
					end
				else
					balanceUpdate,success = insertNode(locNode.left,insertNode,updateData)
					if balanceUpdate != 0
						locNode.balance = locNode.balance - 1
						if locNode.balance == 0
							return 0,success
						elsif locNode.balance == -1
							return 1,success
						end

						if locNode.left.balance < 0
							rightRotation(locNode)
							locNode.balance = 0
							locNode.parent.balance = 0
							locNode.subLeftMax = locNode.parent.subRightMax
							locNode.parent.subRightMax = -Float::INFINITY
						else
							leftRotation(locNode.left)
							rightRotation(locNode)
							locNode.parent.resetBalance

							locNode.subLeftMax = locNode.parent.subRightMax
							locNode.parent.left.subRightMax = locNode.parent.subLeftMax
							locNode.parent.subRightMax = -Float::INFINITY
							locNode.parent.subLeftMax = -Float::INFINITY
						end

						locNode.parent.updateMaxScores
					end
					return 0,success
				end
			elsif diff < 0
				if locNode.right.nil?
					locNode.right = insertNode
					insertNode.parent = locNode
					locNode.balance = locNode.balance + 1
					locNode.updateMaxScores
					if locNode.balance == 0
						return 0,true
					else
						return 1,true
					end
				else
					balanceUpdate,success = insertNode(locNode.right,insertNode,updateData)
					if balanceUpdate != 0
						locNode.balance = locNode.balance + 1
						if locNode.balance == 0
							return 0,success
						elsif locNode.balance == 1
							return 1,success
						end

						if locNode.right.balance > 0
							leftRotation(locNode)
							locNode.balance = 0
							locNode.parent.balance = 0
							locNode.subRightMax = locNode.parent.subLeftMax
							locNode.parent.subLeftMax = -Float::INFINITY
						else
							rightRotation(locNode.right)
							leftRotation(locNode)
							locNode.parent.resetBalance

							locNode.subRightMax = locNode.parent.subLeftMax
							locNode.parent.right.subLeftMax = locNode.parent.subRightMax
							locNode.parent.subRightMax = -Float::INFINITY
							locNode.parent.subLeftMax = -Float::INFINITY
						end

						locNode.parent.updateMaxScores
					end
					return 0,success
				end
			else
				if updateData
					locNode.data = insertNode.data
					locNode.data_list = [insertNode.data]
					return 0,false
				else
					locNode.data_list << insertNode.data
					return 0,true
				end
			end
		end

		def removeFromParent(locNode,replacementNode)
			if locNode.parent
				if locNode.parent.left == locNode
					locNode.parent.left = replacementNode
				else
					locNode.parent.right = replacementNode
				end
			else
				@root = replacementNode
			end
		end

		def removeNode(locNode, delNode)
			diff = locNode <=> delNode
			heightDelta = 0
			replacementNode = nil
			removed = false

			if diff == 0
				if locNode.left.nil?
					if locNode.right.nil?
						removeFromParent(locNode,nil)
						locNode.parent.updateMaxScores if locNode.parent
						removed = true
						return -1,removed
					end
					removeFromParent(locNode,locNode.right)
					locNode.right.parent = locNode.parent
					locNode.parent.updateMaxScores if locNode.parent
					locNode.right = nil
					removed = true
					return -1,removed
				end

				if locNode.right.nil?
					removeFromParent(locNode,locNode.left)
					locNode.left.parent = locNode.parent
					locNode.parent.updateMaxScores if locNode.parent
					locNode.left = nil
					removed = true
					return -1,removed
				end

				if locNode.balance < 0
					replacementNode = locNode.left
					while replacementNode.right do
						replacementNode = replacementNode.right
					end
				else
					replacementNode = locNode.right
					while replacementNode.left do
						replacementNode = replacementNode.left
					end
				end

				heightDelta,removed = removeNode(locNode,replacementNode)

				locNode.right.parent = replacementNode if locNode.right
				locNode.left.parent = replacementNode if locNode.left

				replacementNode.left = locNode.left
				replacementNode.right = locNode.right
				replacementNode.parent = locNode.parent
				replacementNode.balance = locNode.balance

				if locNode == @root
					@root = replacementNode
					replacementNode.updateMaxScores
				else
					if locNode == locNode.parent.left
						locNode.parent.left = replacementNode
					else
						locNode.parent.right = replacementNode
					end
					replacementNode.updateMaxScores
				end

				locNode.left = nil
				locNode.right = nil

				if replacementNode.balance == 0
					return heightDelta,removed
				end
				removed = true
				return 0,removed
			elsif diff > 0
				if locNode.left
					heightDelta,removed = removeNode(locNode.left,delNode)
					if heightDelta != 0
						locNode.balance = locNode.balance + 1
						if locNode.balance == 0
							return -1,removed
						elsif locNode.balance == 1
							return 0,removed
						end

						if locNode.right.balance == 1
							leftRotation(locNode)
							locNode.parent.balance = 0
							locNode.parent.left.balance = 0

							locNode.subRightMax = locNode.parent.subLeftMax
							locNode.parent.subLeftMax = nil
							locNode.parent.updateMaxScores

							return -1,removed
						elsif locNode.right.balance == 0
							leftRotation(locNode)
							locNode.parent.balance = -1
							locNode.parent.left.balance = 1

							locNode.subRightMax = locNode.parent.subLeftMax
							locNode.parent.subLeftMax = nil
							locNode.parent.updateMaxScores

							return 0,removed
						end
						rightRotation(locNode.right)
						leftRotation(locNode)
						locNode.parent.resetBalance

						locNode.subRightMax = locNode.parent.subLeftMax
						locNode.parent.right.subLeftMax = locNode.parent.subRightMax

						locNode.parent.subRightMax = nil
						locNode.parent.subLeftMax = nil
						locNode.parent.updateMaxScores

						return -1,removed
					end
				end
			elsif diff < 0
				if locNode.right
					heightDelta,removed = removeNode(locNode.right,delNode)
					if heightDelta != 0
						locNode.balance = locNode.balance - 1
						if locNode.balance == 0
							return 1,removed
						elsif locNode.balance == -1
							return 0,removed
						end

						if locNode.left.balance == -1
							rightRotation(locNode)
							locNode.parent.balance = 0
							locNode.parent.right.balance = 0

							locNode.subLeftMax = locNode.parent.subRightMax
							locNode.parent.subRightMax = nil
							locNode.parent.updateMaxScores

							return -1,removed
						elsif locNode.left.balance == 0
							rightRotation(locNode)
							locNode.parent.balance = 1
							locNode.parent.right.balance = -1

							locNode.subLeftMax = locNode.parent.subRightMax
							locNode.parent.subRightMax = nil
							locNode.parent.updateMaxScores

							return 0,removed
						end
						leftRotation(locNode.left)
						rightRotation(locNode)
						locNode.parent.resetBalance

						locNode.subLeftMax = locNode.parent.subRightMax
						locNode.parent.left.subRightMax = locNode.parent.subLeftMax

						locNode.parent.subLeftMax = nil
						locNode.parent.subRightMax = nil
						locNode.parent.updateMaxScores

						return -1,removed
					end
				end
			end

			return 0,removed
		end

		def leftRotation(locNode)
			newRoot = locNode.right
			locNode.right = newRoot.left
			if locNode.right
				locNode.right.parent = locNode
			end
			newRoot.left = locNode

			newRoot.parent = locNode.parent
			locNode.parent = newRoot
			if newRoot.parent
				if ((newRoot.parent <=> newRoot) > -1)
					newRoot.parent.left = newRoot
				else
					newRoot.parent.right = newRoot
				end
			else
				@root = newRoot
			end
		end

		def rightRotation(locNode)
			newRoot = locNode.left
			locNode.left = newRoot.right
			if locNode.left
				locNode.left.parent = locNode
			end
			newRoot.right = locNode

			newRoot.parent = locNode.parent
			locNode.parent = newRoot
			if newRoot.parent
				if ((newRoot.parent <=> newRoot) > -1)
					newRoot.parent.left = newRoot
				else
					newRoot.parent.right = newRoot
				end
			else
				@root = newRoot
			end
		end

		def stabNode(node, minScore, maxScore, results)
			# Traverse the left subtree if it might contain intersecting ranges.
			# subLeftMax is the max endpoint across the left subtree only, so if the
			# query starts past it, nothing in the left subtree can overlap.
			if node.left && node.subLeftMax && minScore <= node.subLeftMax
				stabNode(node.left, minScore, maxScore, results)
			end

			# Check if the current node intersects the query range.
			# Emit one clone per data entry so callers can do stab(x).map(&:data)
			# and get every value that was inserted at this interval.
			if node.scores[1] >= minScore && node.scores[0] <= maxScore
				node.data_list.each do |entry|
					cloned = node.clone
					cloned.data = entry
					results << cloned
				end
			end

			# Traverse the right subtree if it might contain intersecting ranges.
			# Right subtree starts past node.scores[0], and subRightMax bounds its
			# endpoints — prune when either excludes an overlap.
			if node.right && maxScore >= node.scores[0] &&
				 (node.subRightMax.nil? || minScore <= node.subRightMax)
				stabNode(node.right, minScore, maxScore, results)
			end
		end
	end
end
