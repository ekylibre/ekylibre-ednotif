# encoding: utf-8
require 'test_helper'
require 'yaml_nomen'

class Ednotif::InTranscoderTest < ActiveSupport::TestCase

  setup do
    files = Dir.glob(Ednotif.in_transcoding_dir.join('*')) - Dir.glob(Ednotif.in_transcoding_dir.join('*.exception.yml'))
    YamlNomen.load(:incoming, files)
  end

  test 'convert hash response from savon to ekylibre response on a get list operation example' do
    savon_hashed_response = {
        informations_message: {:date_heure_generation => Date.parse("Tue, 01 Mar 2016 09:30:47 +0000"),
                               :exploitation => {:code_pays => "FR", :numero_exploitation => "75998877"},
                               :date_debut => Date.parse("Wed, 01 Jan 2014"),
                                                         :date_fin => Date.parse("Sun, 01 Mar 2015"),
                                                         :stock_boucles => true},
        bovins: {bovin: [{identite_bovin: {bovin: {:code_pays => "FR", :numero_national => "7599882110"},
                                           sexe: "F",
                                           type_racial: "34",
                                           date_naissance: {:date => Date.parse("Sat, 01 Feb 2014"), :temoin_completude => "0"},
                                           numero_travail: "2110",
                                           nom_bovin: "TITOUNETTE",
                                           statut_filie: false,
                                           mere_porteuse: {:bovin => {:code_pays => "FR", :numero_national => "7599881110"}, :type_racial => "34"},
                                           pere_ipg: {:bovin => {:code_pays => "FR", :numero_national => "7599880110"}, :type_racial => "34"},
                                           exploitation_naissance: {:code_pays => "FR", :numero_exploitation => "75998877"}},
                          periodes_presences: {:periode_presence => {:entree => {:date_entree => Date.parse("Sat, 01 Feb 2014"), :cause_entree => "N"}}}},
                         {identite_bovin: {bovin: {:code_pays => "FR", :numero_national => "7599881110"},
                                           sexe: "F",
                                           type_racial: "34",
                                           date_naissance: {:date => Date.parse("Tue, 18 May 2010"), :temoin_completude => "0"},
                                           numero_travail: "1110",
                                           nom_bovin: "RESINE",
                                           statut_filie: false,
                                           mere_porteuse: {:bovin => {:code_pays => "FR", :numero_national => "7599881199"}, :type_racial => "34"},
                                           pere_ipg: {:bovin => {:code_pays => "FR", :numero_national => "7599880198"}, :type_racial => "34"},
                                           exploitation_naissance: {:code_pays => "FR", :numero_exploitation => "75998877"}},
                          periodes_presences: {:periode_presence =>
                                                   [{:entree => {:date_entree => Date.parse("Tue, 18 May 2010"), :cause_entree => "N"}, :sortie => {:date_sortie => Date.parse("Thu, 21 Jul 2011"), :cause_sortie => "H"}}, {entree: {:date_entree => Date.parse("Fri, 30 Sep 2011"), :cause_entree => "P"}}]}},
                         {identite_bovin: {bovin: {:code_pays => "FR", :numero_national => "7599880110"},
                                           sexe: "M",
                                           type_racial: "34",
                                           date_naissance: {:date => Date.parse("Tue, 10 Oct 2006"), :temoin_completude => "0"},
                                           numero_travail: "0110",
                                           nom_bovin: "HERMES",
                                           statut_filie: false,
                                           mere_porteuse: {:bovin => {:code_pays => "FR", :numero_national => "7599889910"}, :type_racial => "34"},
                                           pere_ipg: {:bovin => {:code_pays => "FR", :numero_national => "7599880990"}, :type_racial => "34"},
                                           exploitation_naissance: {:code_pays => "FR", :numero_exploitation => "75998878"}},
                          periodes_presences: {:periode_presence => {:entree => {:date_entree => Date.parse("Tue, 12 Jun 2012"), :cause_entree => "A"}}}}]},
        boucles: {serie_boucles: {:code_pays => "FR", :debut_serie => "1000000000", :quantite => "10"}}}


    expected_ekylibre_response = {
        generation_datetime: Date.parse("Tue, 01 Mar 2016 09:30:47 +0000"),
        farm: {:country_code => "fr", :farm_number => "75998877"},
        start_date: Date.parse("Wed, 01 Jan 2014"),
        end_date: Date.parse("Sun, 01 Mar 2015"),
        stock: true,
        animals: [{identity: {:country_code => "fr",
                              :identification_number => "7599882110",
                              :sex => "female",
                              :race_code => "bos_taurus_limousine",
                              :birth_date => {:date => Date.parse("Sat, 01 Feb 2014"), :witness => nil},
                              :work_number => "2110",
                              :name => "TITOUNETTE",
                              :cpb_filiation_status => false,
                              :mother => {:country_code => "fr", :identification_number => "7599881110", :race_code => "bos_taurus_limousine"},
                              :father => {:country_code => "fr", :identification_number => "7599880110", :race_code => "bos_taurus_limousine"},
                              :farm_number => "75998877"},
                   mouvements: [{:entry => {:entry_date => Date.parse("Sat, 01 Feb 2014"), :entry_reason => "birth"}}]},
                  {identity: {:country_code => "fr",
                              :identification_number => "7599881110",
                              :sex => "female",
                              :race_code => "bos_taurus_limousine",
                              :birth_date => {:date => Date.parse("Tue, 18 May 2010"), :witness => nil},
                              :work_number => "1110",
                              :name => "RESINE",
                              :cpb_filiation_status => false,
                              :mother => {:country_code => "fr", :identification_number => "7599881199", :race_code => "bos_taurus_limousine"},
                              :father => {:country_code => "fr", :identification_number => "7599880198", :race_code => "bos_taurus_limousine"},
                              :farm_number => "75998877"},
                   mouvements: [
                       {entry: {:entry_date => Date.parse("Tue, 18 May 2010"), :entry_reason => "birth"}, exit: {:exit_date => Date.parse("Thu, 21 Jul 2011"), :exit_reason => "loan"}},
                       {:entry => {:entry_date => Date.parse("Fri, 30 Sep 2011"), :entry_reason => "loan"}}]},
                  {identity: {:country_code => "fr",
                              :identification_number => "7599880110",
                              :sex => "male",
                              :race_code => "bos_taurus_limousine",
                              :birth_date => {:date => Date.parse("Tue, 10 Oct 2006"), :witness => nil},
                              :work_number => "0110",
                              :name => "HERMES",
                              :cpb_filiation_status => false,
                              :mother => {:country_code => "fr", :identification_number => "7599889910", :race_code => "bos_taurus_limousine"},
                              :father => {:country_code => "fr", :identification_number => "7599880990", :race_code => "bos_taurus_limousine"},
                              :farm_number => "75998878"},
                   mouvements: [{:entry => {:entry_date => Date.parse("Tue, 12 Jun 2012"), :entry_reason => "purchase"}}]}],
        buckles: [{:country_code => "fr", :start_date => "1000000000", :quantity => "10"}]}

    doc = Ednotif::InTranscoder.convert savon_hashed_response

    assert_equal expected_ekylibre_response, doc

  end
end