sub get_agents {
    my( $twig, $ename)= @_;
    @agents= $ename->children;
    foreach my $agents (@agents) {
			$a_list->{"status"} = $agents->att('status');
			$a_list->{"source.agent.id"} = $agents->first_child('source.agent.id')->text;
			$a_list->{"source.agent.name"} = $agents->first_child('source.agent.name')->text;
			$a_list->{"source.agent.progid"} = $agents->first_child('source.agent.progid')->text;
			$a_list->{"result"} = $agents->first_child('result')->text;
			$a_list->{"result.id"} = $agents->first_child('result.id')->text;
			$a_list->{"target.agent.id"} = $agents->first_child('target.agent.id')->text;
			$a_list->{"target.agent.name"} = $agents->first_child('target.agent.name')->text;
			$a_list->{"target.agent.progid"} = $agents->first_child('target.agent.progid')->text;
			$a_list->{"target.agent.locale"} = $agents->first_child('target.agent.locale')->text;
		$count++;
#      print $agents->{"source.agent.id"} . "," . $agents->{"source.agent.name"} . "," . $agents->{"source.agent.progid"} . "," . $agents->{"result"} . "," . $agents->{"result.id"} . "," . $agents->{"target.agent.id"} . "," . $agents->{"target.agent.name"} . "," . $agents->{"target.agent.progid"} . "," . $agents->{"target.agent.locale"} . "\n";
	}
#		print "Agent count: $count \n";
}


sub call_results {
    my( $twig, $ename)= @_;
    @c_results = $ename->children;
    foreach my $c_results (@c_results) {
			   my $cname = $c_results->name;
			   $cfa2->{"call.time"} = $c_results->att('call.time');
			   $cfa2->{"server"} = $c_results->att('server');
			   my @crchildren = $c_results->children;
   			   foreach my $crchild ( @crchildren ) {
                     my $name = $crchild->name;
					 $cfa2->{"call.HRESULT"} = $crchild->string_value;
					 $cfa2->{"call.resultStr"} = $crchild->string_value;
         }
#	print $cfa2->{"call.time"} . "," . $cfa2->{"server"} . "," . $cfa2->{"call.HRESULT"} . "," . $cfa2->{"call.resultStr"} . "\n";
	$c_count++;
    }
}
