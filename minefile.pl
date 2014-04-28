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
    my($weightHunpound) = -567;
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
        $title = &SAFE($1);
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
        if ($tomine =~ /Publisher:\<\/span><span class=.*?>(.*?)\<\/span>/) {
          $publisher = &SAFE($1);
        }
        if ($tomine =~ /Edition\/Volume:<\/span><span class=".*?">(.*?)\<\/span>/) {
          $rawedition = &SAFE($1);
        }
        if ($tomine =~ /Publish Date:<\/span><span class=".*?">(.*?)\<\/span>/) {
          $pubdate = &SAFE($1);
          if ($pubdate =~ /(\d\d)\/(\d\d)\/(\d\d\d\d)/) {
            $pubdate = $3."-".$1."-".$2;
          }else{
            die "Weird pubdate $pubdate for $isbn";
          }
        }
        if ($tomine =~ /Publish Status:<\/span><span class=".*?">(.*?)\<\/span>/) {
          $pubstatus = &SAFE($1);
          if ($pubstatus =~ /NOT YET PUBLISHED/i) {
            $pubstatus = "NotYetP";
          } elsif ($pubstatus =~ /APPLY DIRECT/i) {
            $pubstatus = "ApplyDirect";
          } elsif ($pubstatus =~ /AD/i) {
            $pubstatus = "ApplyDirect";
          } elsif ($pubstatus =~ /PUBLISHER OUT OF STOCK/i) {
            $pubstatus = "PubOOS";
          } elsif ($pubstatus =~ /PERMANENTLY OUT OF STOCK/i) {
            $pubstatus = "PermOOS";
          } elsif ($pubstatus =~ /OUT OF PRINT/i) {
            $pubstatus = "OOP";
          } elsif ($pubstatus =~ /OUT OF BUSINESS/i) {
            $pubstatus = "OOBusiness";
          } elsif ($pubstatus =~ /UNABLE TO LOCATE/i) {
            $pubstatus = "OOBusiness";
          } elsif ($pubstatus =~ /PRODUCT CANCELLED/i) {
            $pubstatus = "PermOOS";
          } elsif ($pubstatus) {
            die "___________\n$_\nPUBLISH STATUS IS UNRECOGNIZED ($pubstatus) FOR ISBN $isbn \n\n";
          }
        }
      }
      elsif (/^ZAUTHOR:(.*)$/) {
        $rawauthorlist = $1;
        $author = "";
        while (1) {
          if ($rawauthorlist =~ /\<a.*?\"\>(.*?)\<\/a\>/) {
            if ($author) {
              $author .= "; " . &SAFE($1);
            } else {
              $author = &SAFE($1);
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
        if ($tomine =~ /Included Format:\<\/td\>\<td\>(.*?)\<\/td\>/) {
          $includedbonus = "Includes " . &SAFE($1) . ". ";
        }
        if ($tomine =~ /Physical Description:\<\/td\>\<td\>(.*?)\<\/td\>/) {
          $physdescr = $1;
          if ($physdescr =~ /([\d\.]+) lbs\./) {
            $weightHunpound = int($1 * 100);
          }
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

    if ($langcode) {
      $langcode = "English" if ($langcode =~ /ENG/i);
      $langcode = "Spanish/Espanol" if ($langcode =~ /ESP/i);
      $langcode = "Spanish/Espanol" if ($langcode =~ /SPA/i);
      $langcode = "French/Francais" if ($langcode =~ /FRA/i);
      $langcode = "German/Deutch" if ($langcode =~ /DEU/i);
    }

    $title = $LABELisAudiobook . $title;

    if ( ! $isbn ) {
      print STDERR "NO DATA FOUND IN FILE $filetoparse\n";
      return;
    }
    if ( ! $title ) {
      print STDERR "NO TITLE FOUND FOR ISBN $isbn\n";
      return;
    }
    
    if ($weightHunpound < 0) {
      print STDERR "ISBN $isbn -- no weight info, but allowing through\n";
      $weightHunpound = "NULL";
    }


    # MID-2007: New way to identify study guides
    if ($rawedition =~ /study ?guide/i) {
      $warnings .= "Title was adjusted. ";
      $title = "STUDY GUIDE: " . $title;
    } elsif ($rawedition =~ /signed/i) {
      $warnings .= "Title was adjusted. Error in ContentCafe (use of 'signed' instead of StGd). ";
      $title = "STUDY GUIDE: " . $title;
      $rawedition =~ s/signed/StGd/i;
    } elsif ($rawedition =~ /student ?guide/i) {
      $warnings .= "Title was adjusted. ";
      $title = "STUDY GUIDE: " . $title;
    }

    if ($rawedition =~ /workbook/i) {
      $warnings .= "Title was adjusted. ";
      $title = "WORKBOOK: " . $title;
    }

    if ($rawedition =~ /solution/i) {
      $warnings .= "Title was adjusted. ";
      $title = "SOLUTIONS MANUAL: " . $title;
    }


    # JULY 2007: Trying to recognize cases of only one volume
    if ($rawedition =~ /vol\. ?(\w+)/) {
      $warnings .= "Title was adjusted.  URGENT: ambiguity regarding volume specifications. ";
      $title .= " (VOLUME " . $1 . ")";
    }


    $rawedition =~ s/;$//;

    $rawedition =~ s/Edit.(\d\d)/\1th./;
    $rawedition =~ s/Edit.1/1st./;
    $rawedition =~ s/Edit.(2)/\1nd./;
    $rawedition =~ s/Edit.3/3rd./;
    $rawedition =~ s/Edit.(\d)/\1th./;



    $author =~ s/\(EDT\)/(Editor)/g;
    $author =~ s/\(PHT\)/(Photos)/g;
    $author =~ s/\(ILT\)/(Illustrator)/g;
    $author =~ s/\(TRN\)/(Translator)/g;


    # BUILD THE EXTRA-DESCRIPTION (language, physical description)
    # BUILD THE EXTRA-DESCRIPTION (language, physical description)
    # BUILD THE EXTRA-DESCRIPTION (language, physical description)


    #### I've decided BINDING should be added to description by marketplaces
    #if ($binding) {
    #        $attributes .= "Binding: $binding" . ". ";
    #        $canonbinding = $binding;
    #        if ($canonbinding =~ /LIBRARY/i) {
    #                 $canonbinding = 'HARDCOVER';
    #        }
    #}


    if ($langcode) {
      $langcode = "English" if ($langcode eq "ENG");
      $langcode = "Spanish/Espanol" if ($langcode eq "ESP");
      $langcode = "French/Francais" if ($langcode eq "FRA");
      $langcode = "German/Deutch" if ($langcode eq "DEU");
    }

    #    #if ($physdescr) {
    #       #$attributes .= " Physical description: $physdescr";
    #    #}

    my($thesql) = "UPDATE inventory SET BOOLneedsDetailsDownload='N', PhysicalDescr='$includedbonus$physdescr', InternalStatus='$pubstatus', Edition='$rawedition$editioninfoFoundJustAfterTitle', Weight=$weightHunpound, Type='$prodtype', Title='$title', Author='$author', Binding='$binding', Lang='$langcode', Manufacturer='$publisher', PubDate='$pubdate', BOOLhasAlternateFormats=$BOOLhasAlternateFormats     WHERE  Id='$isbn' LIMIT 1;\n";

    print $thesql;

  }

  &UpdateInventoryRecordViaParse_BOOK($ARGV[0]);
