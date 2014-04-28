sub MarkDownloadStatus
  {
    my($ISBN) = $_[0];
    my($newstat) = $_[1];
    my($thesql) = "UPDATE inventory SET BOOLneedsDetailsDownload='$newstat' WHERE  Id='$ISBN' LIMIT 1;\n";
    &SQLupdate($thesql);
  }


sub SAFE
  {
    my($x) = $_[0];
    $x =~ s/\<a href=\"(.*?)\"\>//gi;
    $x =~ s/\<a href=\'(.*?)\'\>//gi;
    $x =~ s/\<font color=.red.\>//gi;
    $x =~ s/\<\/font\>//gi;
    $x =~ s/\<\/a\>//gi;
    $x =~ s/\&nbsp;/ /g;
    $x =~ s/[\r\n]//g;
    $x =~ s/\s*$//;
    $x =~ s/\\/./g;
    $x =~ s/\<br\>//gi;
    $x =~ s/\& /__AmPeRsAnD__ /g;
    $x =~ s/([A-Z])\&([A-Z][A-Z])/\1__AmPeRsAnD__\2/g;

    print STDERR "Percent sign present in text for $isbn: $x\n" if ($x =~ /[\%]/);

    # THE VERY LAST THINGS TO DO:
    $x =~ s/__AmPeRsAnD__/\&/g;
    $x =~ s/\'/\'\'/g;
    return $x;
  }




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
        if ($tomine =~ /Publisher:\<\/span><span class=.*?>(.*)\<\/span>/) {
          $publisher = $1;
        }
        if ($tomine =~ /Edition\/Volume:<\/span><span class=".*?">(.*?)\<\/span>/) {
          $rawedition = $1;
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
      elsif (/^ZLOINF:/) {
        $tomine = $';
        if ($tomine =~ /Language Code:\<\/td\>\<td\>(.*?)\<\/td\>/) {
          $langcode = $1;
        }
      }
      elsif (/^ZPHYS:/) {
        $tomine = $';
        if ($tomine =~ /Primary Physical Format:\<\/td\>\<td\>(.*?)\<\/td\>/) {
          $binding = $1;
        }
        if ($tomine =~ /Physical Description:\<\/td\>\<td\>(.*?)\<\/td\>/) {
          $descr = $1;
          if ($descr =~ /([\d\.]+) lbs\./) {
            $weightHunpound = $1 * 100;
          }
          $binding = $1;
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

