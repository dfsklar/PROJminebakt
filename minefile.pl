sub UpdateInventoryRecordViaParse_BOOK
  {
    my($filetoparse) = $_[0];  # filename actually

    my($binding);
    my($prodtype);
    my($numresults);
    my($rawedition);
    my($attributes) = "";
    my($includedbonus);
    my($pubdate);
    my($physdescr);
    my($weight);
    my($weightHunpound);
    my($langcode);
    my($publisher);
    my($title);
    my($author);
    my($pubstatus);

    my($BOOLhasAlternateFormats) = 0;

    my($editioninfoFoundJustAfterTitle) = '';

    my($LABELisAudiobook) = '';

    my($warnings);


    open FIN, "<" . $filetoparse;


    while (<FIN>) {
      chomp;
      if (/^ZTITLE:(.*)$/) {
        $title = $1;
      }
      elsif (/^ZDETAILS:/) {
        $tomine = "";
        while (1) {
          $_ = "";
          $_ = <FIN>;
          chomp;
          last if eof(FIN);
          $_ =~ s/^ *//;
          $_ =~ s/ *$//;
          $tomine .= $_;
        }
        die $tomine;
      }
      elsif (/^ZAUTHOR:(.*)$/) {
        $rawauthorlist = $1;
        $author = "";
        while (1) {
          if ($rawauthorlist =~ /\<a.*?\"\>(.*?)\<\/a\>/) {
            if ($author) {
              $author .= "; " . $1;
            } else {
              $author = $1;
            }
            $rawauthorlist = $';
          }else{
            last;
          }
        }
      }
      elsif (/^ZPRODINF:/) {
        $tomine = $';
        if ($tomine =~ /ISBN:\<\/td\>\<td\>(.*?)\<\/td\>/) {
          $isbn = $1;
        }
      }
      elsif (/^ZBTINF:/) {
        $tomine = $';
        if ($tomine =~ /Product Type:\<\/td\>\<td\>(.*?)\<\/td\>/) {
          $prodtype = $1;
          if ($prodtype eq "Book") {
            $prodtype = 'Book';
          } elsif ($prodtype eq "Audio") {
            $prodtype = 'Book';
            $LABELisAudiobook = 'AUDIOBOOK: ';
          } else {
            print STDERR "UNEXPEC PRODTYPE $prodtype FOR ISBN $isbn \n";
            # &MarkDownloadStatus($isbn,'Y'); # "Y" means needs a fresh download
            return;
          }
        }
      }
    }
  }


  &UpdateInventoryRecordViaParse_BOOK("exports/9781444154344.data");

