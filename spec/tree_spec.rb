require 'spec_helper'

describe Intervals::Tree do
	let(:tree) { Intervals::Tree.new }

	context "creation" do
		describe "#initialize" do
			it { Intervals::Tree.new.size.should eq 0}
			it { Intervals::Tree.new.root.should be nil}
		end
	end

	describe "#insert" do
		context "insert node in empty tree" do
			it "inserts at root" do
				tree.insert(0,10)
				tree.root.scores.should eq [0,10]
			end

			it "increases tree size" do
				tree.insert(0,10)
				tree.size.should eq 1
			end
		end

		context "inserting duplicates" do
			before(:each) { tree.insert(0,10,"cheese") }

			it { tree.insert(0,10,"taco").should be true }
			it "increases tree size" do
				tree.insert(0,10,"taco")
				tree.size.should eq 2
			end
			it "accumulates data entries on the existing node" do
				tree.insert(0,10,"taco")
				tree.root.data_list.should eq ["cheese","taco"]
			end
			it "returns every data entry from stab" do
				tree.insert(0,10,"taco")
				tree.stab(5).map(&:data).should eq ["cheese","taco"]
			end
			it "does not create a new tree node" do
				tree.insert(0,10,"taco")
				tree.root.left.should be nil
				tree.root.right.should be nil
			end
		end

		context "rotations" do
			before(:each) do
				tree.insert(150,250)
				tree.insert(200,300)
				tree.insert(100,200)
			end

			it { tree.root.scores.should eq [150,250] }
			it { tree.root.left.scores.should eq [100,200] }
			it { tree.root.right.scores.should eq [200,300] }
			it { tree.size.should eq 3 }

			context "left-left rotation" do
				before(:each) do
					tree.insert(25,50)
					tree.insert(0,25)
				end

				it "does not change root" do
					tree.root.scores.should eq [150,250]
				end
				it { tree.root.left.scores.should eq [25,50] }
				it { tree.root.left.left.scores.should eq [0,25] }
				it { tree.root.left.right.scores.should eq [100,200] }
				it { tree.root.subLeftMax.should eq 200 }
			end

			context "right-right rotation" do
				before(:each) do
					tree.insert(250,300)
					tree.insert(300,350)
				end

				it "does not change root" do
					tree.root.scores.should eq [150,250]
				end
				it { tree.root.right.scores.should eq [250,300] }
				it { tree.root.right.left.scores.should eq [200,300] }
				it { tree.root.right.right.scores.should eq [300,350] }
				it { tree.root.subRightMax.should eq 350 }
			end

			context "left-right rotation" do
				before(:each) do
					tree.insert(50,100)
					tree.insert(75,125)
				end

				it "does not change root" do
					tree.root.scores.should eq [150,250]
				end
				it { tree.root.left.scores.should eq [75,125] }
				it { tree.root.left.left.scores.should eq [50,100] }
				it { tree.root.left.right.scores.should eq [100,200] }
				it { tree.root.subLeftMax.should eq 200 }
			end

			context "right-left rotation" do
				before(:each) do
					tree.insert(250,300)
					tree.insert(225,275)
				end

				it "does not change root" do
					tree.root.scores.should eq [150,250]
				end
				it { tree.root.right.scores.should eq [225,275] }
				it { tree.root.right.left.scores.should eq [200,300] }
				it { tree.root.right.right.scores.should eq [250,300] }
				it { tree.root.subRightMax.should eq 300 }
			end
		end

	end

	describe "#insert!" do
		context "inserting duplicates" do
			before(:each) { tree.insert(0,10,"cheese")}

			it { tree.root.data.should eq "cheese" }
			it { tree.insert!(0,10,"taco").should_not be true}
			it "does not increase tree size" do
				tree.insert!(0,10,"taco")
				tree.size.should_not eq 2
			end
			it "updates the node data" do
				tree.insert!(0,10,"taco")
				tree.root.data.should eq "taco"
			end
		end
	end

	describe "#remove" do
		before(:each) do
			tree.insert(100,200)
			tree.insert(200,300)
			tree.insert(150,250)
			tree.insert(300,400)
			tree.insert(400,500)
			tree.insert(50,100)
			tree.insert(75,125)
			tree.insert(25,50)
			tree.insert(0,25)
			tree.insert(51,101)
		end

		it { tree.remove(0,25).should be true }
		it { tree.remove(0,24).should be false }

		context "two ranges removed" do
			before(:each) do
				tree.remove(100,200)
				tree.remove(50,100)
			end

			it { tree.stab(23).length.should eq 1 }
			it "returns a single range" do
				results = tree.stab(23).map{|n| n.scores }.sort{|a,b| a[0] <=> b[0]}
				results[0].should eq [0,25]
			end

			it { tree.stab(40).length.should eq 1 }
			it "returns a single range" do
				results = tree.stab(40).map{|n| n.scores }.sort{|a,b| a[0] <=> b[0]}
				results[0].should eq [25,50]
			end

			it { tree.stab(77).length.should eq 2 }
			it "returns two ranges" do
				results = tree.stab(77).map{|n| n.scores }.sort{|a,b| a[0] <=> b[0]}
				results[0].should eq [51,101]
				results[1].should eq [75,125]
			end

			it { tree.stab(175).length.should eq 1 }
			it "returns a single range" do
				results = tree.stab(175).map{|n| n.scores }.sort{|a,b| a[0] <=> b[0]}
				results[0].should eq [150,250]
			end

			it { tree.stab(350).length.should eq 1 }
			it "returns a single range" do
				results = tree.stab(350).map{|n| n.scores }.sort{|a,b| a[0] <=> b[0]}
				results[0].should eq [300,400]
			end
		end

		context "with a data argument" do
			let(:bucket_tree) do
				t = Intervals::Tree.new
				t.insert(0,10,"a")
				t.insert(0,10,"b")
				t.insert(0,10,"c")
				t
			end

			it "removes only the matching entry" do
				bucket_tree.remove(0,10,"b").should be true
				bucket_tree.stab(5).map(&:data).should eq ["a","c"]
			end

			it "decrements size by one" do
				bucket_tree.remove(0,10,"b")
				bucket_tree.size.should eq 2
			end

			it "returns false when the data entry is not present" do
				bucket_tree.remove(0,10,"z").should be false
				bucket_tree.size.should eq 3
			end

			it "returns false when the interval is not present" do
				bucket_tree.remove(1,2,"a").should be false
			end

			it "falls through to structural removal when the last entry is removed" do
				bucket_tree.remove(0,10,"a")
				bucket_tree.remove(0,10,"b")
				bucket_tree.remove(0,10,"c")
				bucket_tree.size.should eq 0
				bucket_tree.root.should be nil
			end

			it "keeps node.data pointing at the new first entry after removing the head" do
				bucket_tree.remove(0,10,"a")
				bucket_tree.root.data.should eq "b"
			end
		end

		context "without a data argument on a bucketed interval" do
			let(:bucket_tree) do
				t = Intervals::Tree.new
				t.insert(0,10,"a")
				t.insert(0,10,"b")
				t
			end

			it "drops the whole bucket" do
				bucket_tree.remove(0,10).should be true
				bucket_tree.size.should eq 0
				bucket_tree.root.should be nil
			end
		end
	end

	describe "#stab" do
		before(:each) do
			tree.insert(100,200)
			tree.insert(200,300)
			tree.insert(150,250)
			tree.insert(300,400)
			tree.insert(400,500)
			tree.insert(50,100)
			tree.insert(75,125)
			tree.insert(25,50)
			tree.insert(0,25)
		end


		it { tree.stab(23).length.should eq 1 }
		it "returns a single range" do
			results = tree.stab(23).map{|n| n.scores }.sort{|a,b| a[0] <=> b[0]}
			results[0].should eq [0,25]
		end

		it { tree.stab(40).length.should eq 1 }
		it "returns a single range" do
			results = tree.stab(40).map{|n| n.scores }.sort{|a,b| a[0] <=> b[0]}
			results[0].should eq [25,50]
		end

		it { tree.stab(77).length.should eq 2 }
		it "returns two ranges" do
			results = tree.stab(77).map{|n| n.scores }.sort{|a,b| a[0] <=> b[0]}
			results[0].should eq [50,100]
			results[1].should eq [75,125]
		end

		it { tree.stab(175).length.should eq 2 }
		it "returns a two ranges" do
			results = tree.stab(175).map{|n| n.scores }.sort{|a,b| a[0] <=> b[0]}
			results[0].should eq [100,200]
			results[1].should eq [150,250]
		end

		it { tree.stab(350).length.should eq 1 }
		it "returns a single range" do
			results = tree.stab(350).map{|n| n.scores }.sort{|a,b| a[0] <=> b[0]}
			results[0].should eq [300,400]
		end

		it { tree.stab(350, 520).length.should eq 2 }
		it "returns all intersected ranges" do
			results = tree.stab(350,520).map{|n| n.scores }.sort{|a,b| a[0] <=> b[0]}
			results.should eq [[300,400], [400,500]]
		end
	end

	describe "#stab with a wide-spanning (catchall) interval" do
		# Regression for a stabNode pruning bug: a wide interval living in the
		# left subtree was skipped when an ancestor's subRightMax fell short of
		# the query value, triggering a premature return.
		it "finds the catchall when no narrower range covers the stab value" do
			tree.insert(0, 1000, "catchall")
			tree.insert(200, 299, "sub_range")
			[[300, 309], [400, 409], [500, 509], [600, 609]].each { |lo, hi| tree.insert(lo, hi) }

			# 750 is inside the catchall but past every narrow range's endpoint,
			# so the buggy prune would bail out before visiting the catchall.
			tree.stab(750).map(&:data).should eq ["catchall"]
		end
	end
end
