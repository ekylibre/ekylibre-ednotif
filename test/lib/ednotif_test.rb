# encoding: utf-8
require 'test_helper'
require 'savon/mock/spec_helper'

class Ekylibre::EdnotifTest < ActiveSupport::TestCase
  include Savon::SpecHelper

  setup do
    savon.mock!
  end

  def fixture_files_path
    Rails.root.join('plugins','ednotif','test','fixture-files')
  end

  teardown do
    savon.unmock!
  end

  ################### OPTIMISTIC TESTING #######################

  #### WSANNUAIRE ####
  test 'get urls' do

    # mock
    message = {
        'tk:ProfilDemandeur': {
            'typ:Entreprise': 'E010',
            'typ:Application': 'Ekylibre'
        },
        'tk:VersionPK': {
            'typ:NumeroVersion': 1.00,
            'typ:CodeSiteVersion': 9,
            'typ:NomService': 'IpBNotif',
            'typ:CodeSiteService': 9
        }
    }

    fixture = fixture_file('ws_annuaire_service/OK-tk_get_url-get_urls.xml').read
    savon.expects(:tk_get_url).with(message: message).returns(fixture)


    options = {
        namespace_identifier: 'tk',
        namespaces: {
            'xmlns:typ': 'http://www.fiea.org/types/'
        }
    }

    # call the service
    client = Savon.client(options.merge(wsdl: Ekylibre::Ednotif.import_dir.join('WsAnnuaire.xml')))
    response = client.call(:tk_get_url, message: message)

    assert response.success?

    assert_equal 'true', response.xpath('//ns3:ReponseStandard/xmlns:Resultat').text

    assert_not_empty response.xpath('//xmlns:UrlGuichet').text
    assert_not_empty response.xpath('//xmlns:WsdlGuichet').text
    assert_not_empty response.xpath('//xmlns:UrlMetier').text
    assert_not_empty response.xpath('//xmlns:WsdlMetier').text

  end

  #### WSGUICHET ####
  test 'get token' do

    # mock
    message = {
        'tk:Identification': {
            'typ:UserId': 'ekilibre01d',
            'typ:Password': 'hUvcA2y5s',
            'typ:Profil': {
                'typ:Entreprise': 'E010',
                'typ:Application': 'Ekylibre'
            }
        }
    }

    fixture = fixture_file('ws_guichet_service/OK-tk_create_identification-get_token.xml').read
    savon.expects(:tk_create_identification).with(message: message).returns(fixture)


    options = {
        namespace_identifier: 'tk',
        namespaces: {
            'xmlns:typ': 'http://www.fiea.org/types/'
        }
    }

    # call the service
    client = Savon.client(options.merge(wsdl: Ekylibre::Ednotif.import_dir.join('WsGuichet.xml')))
    response = client.call(:tk_create_identification, message: message)

    assert response.success?

    assert_equal 'true', response.xpath('//ns3:ReponseStandard/xmlns:Resultat').text

    assert_not_empty response.xpath('//ns3:Jeton').text

  end

  #### WSIPBNOTIF ####

  test 'get list' do

    # mock
    message = {
        'sch:JetonAuthentification': '924ffe40-547f-458e-a06e-f5c9145ed795',
        'sch:Exploitation': {
            'sch:CodePays': 'FR',
            'sch:NumeroExploitation': '01999999'
        },
        'sch:DateDebut': '2016-01-01',
        'sch:StockBoucles': 0
    }

    fixture = fixture_file('ws_ipbnotif_service/OK-ip_b_get_inventaire-get_list.xml').read

    savon.expects(:ip_b_get_inventaire).with(message: message).returns(fixture)

    options = {
        namespace_identifier: 'sch',
        namespaces: {
            'xmlns:sch': 'http://www.idele.fr/XML/Schema/'
        }
    }

    # call the service
    client = Savon.client(options.merge(wsdl: Ekylibre::Ednotif.import_dir.join('WsIpBNotif.xml')))

    response = client.call(:ip_b_get_inventaire, message: message)

    assert_equal 'true', response.xpath('//tns:ReponseStandard/tnsfiea:Resultat').text
    assert_not_empty response.xpath('//tns:NbBovins').text
    assert_not_empty response.xpath('//tns:MessageZip').text

  end


  ################### EXCEPTION HANDLING #######################

  #### WSANNUAIRE ####
  test 'SOAP fault on get urls' do

    # mock
    message = {
        'tk:ProfilDemandeur': {
            'typ:break': 'E010', # UNKNOWN TAG
            'typ:Application': 'Ekylibre'
        },
        'tk:VersionPK': {
            'typ:NumeroVersion': 1.00,
            'typ:CodeSiteVersion': 9,
            'typ:NomService': 'IpBNotif',
            'typ:CodeSiteService': 9
        }
    }

    fixture = fixture_file('ws_annuaire_service/KO-tk_get_urls-malformed_request.xml').read

    response = { code: 500, headers: {}, body: fixture }

    savon.expects(:tk_get_url).with(message: message).returns(response)


    options = {
        namespace_identifier: 'tk',
        namespaces: {
            'xmlns:typ': 'http://www.fiea.org/types/'
        }
    }

    # call the service
    client = Savon.client(options.merge(wsdl: Ekylibre::Ednotif.import_dir.join('WsAnnuaire.xml')))

    exception = assert_raise(Savon::SOAPFault){ client.call(:tk_get_url, message: message) }

    assert_equal( %{(ns2:Client) cvc-complex-type.2.4.a: Invalid content was found starting with element 'typ:break'. One of '{"http://www.fiea.org/types/":Entreprise, "http://www.fiea.org/types/":Zone, "http://www.fiea.org/types/":Application}' is expected.}, exception.message)

  end

  #### WSGUICHET ####

  test 'KO response on get token' do

    # mock
    message = {
        'tk:Identification': {
            'typ:UserId': 'INVALID', #INVALID userId
            'typ:Password': 'hUvcA2y5s',
            'typ:Profil': {
                'typ:Entreprise': 'E010',
                'typ:Application': 'Ekylibre'
            }
        }
    }

    fixture = fixture_file('ws_guichet_service/KO-tk_create_Identification-user_doesnt_exist.xml').read
    savon.expects(:tk_create_identification).with(message: message).returns(fixture)


    options = {
        namespace_identifier: 'tk',
        namespaces: {
            'xmlns:typ': 'http://www.fiea.org/types/'
        }
    }

    # call the service
    client = Savon.client(options.merge(wsdl: Ekylibre::Ednotif.import_dir.join('WsGuichet.xml')))
    response = client.call(:tk_create_identification, message: message)

    assert response.success?

    assert_equal 'false', response.xpath('//ns3:ReponseStandard/xmlns:Resultat').text

    assert_equal 'NTk001', response.xpath('//xmlns:Anomalie/xmlns:Code').text

  end

  #### WSIPBNOTIF ####

  test 'SOAP fault invalid token' do

      # mock
      message = {
          'sch:JetonAuthentification': 'XXXXX', #invalid token
          'sch:Exploitation': {
              'sch:CodePays': 'FR',
              'sch:NumeroExploitation': '01999999'
          },
          'sch:DateDebut': '2016-01-01',
          'sch:StockBoucles': 0
      }

      fixture = fixture_file('ws_ipbnotif_service/KO-ip_b_get_inventaire-invalid_token.xml').read

      response = { code: 500, headers: {}, body: fixture }

      savon.expects(:ip_b_get_inventaire).with(message: message).returns(response)


      options = {
          namespace_identifier: 'tk',
          namespaces: {
              'xmlns:typ': 'http://www.fiea.org/types/'
          }
      }

      # call the service
      client = Savon.client(options.merge(wsdl: Ekylibre::Ednotif.import_dir.join('WsIpBNotif.xml')))

      exception = assert_raise(Savon::SOAPFault){ client.call(:ip_b_get_inventaire, message: message) }

      assert_equal( %{(ns2:Server) Lors de la demande de log : Le jeton fourni n'est pas valide}, exception.message)

    end


  #   test 'raising exception animal already entered while creating cattle entrance on Ednotif' do
  #
  #     authenticated = @tr.authenticate
  #
  #     if authenticated
  #
  #       args = { farm_country_code: 'FR',
  #                farm_number: '01999999',
  #                animal_country_code: 'FR',
  #                animal_id: '3312345678',
  #                entry_date: '2015-02-13',
  #                entry_reason: 'A',
  #                src_farm_country_code: 'FR',
  #                src_farm_number: '01000000',
  #                src_farm_owner_name: 'EKYLIBRE_TEST',
  #                prod_code: nil,
  #                cattle_categ_code: nil
  #       }
  #
  #
  #       exception = assert_raise(::Tele::Idele::EdnotifError::ParsingError){ @tr.create_cattle_entrance args }
  #       assert_equal('9lpBM025', exception.code)
  #
  #     end
  #
  #   end

  #
  #   test 'passing creation cattle entrance on Ednotif' do
  #
  #     authenticated = @tr.authenticate
  #
  #     if authenticated
  #
  #       args = { farm_country_code: 'FR',
  #                farm_number: '01999999',
  #                animal_country_code: 'FR',
  #                animal_id: '3300000005',
  #                entry_date: '2015-02-17',
  #                entry_reason: 'A',
  #                src_farm_country_code: 'FR',
  #                src_farm_number: '01000000',
  #                src_farm_owner_name: 'EKYLIBRE_TEST',
  #                prod_code: nil,
  #                cattle_categ_code: nil
  #       }
  #
  #       status = @tr.create_cattle_entrance args
  #
  #       assert_equal('waiting validation', status)
  #
  #     end
  #
  #   end

  #   test 'passing creation cattle exit on Ednotif' do
  #
  #     authenticated = @tr.authenticate
  #
  #     if authenticated
  #
  #       args = { farm_country_code: 'FR',
  #                farm_number: '01999999',
  #                animal_country_code: 'FR',
  #                animal_id: '3300000004',
  #                exit_date: '2015-02-17',
  #                exit_reason: 'H',
  #                dest_country_code: 'FR',
  #                dest_farm_number: '01000000',
  #                dest_owner_name: 'EKYLIBRE_TEST_DEST'
  #       }
  #
  #       status = @tr.create_cattle_exit args
  #
  #       assert_equal('validated', status)
  #
  #     end
  #
  #   end

  #   test 'raising exception animal already exited while creating cattle exit on Ednotif' do
  #
  #     authenticated = @tr.authenticate
  #
  #     if authenticated
  #
  #       args = { farm_country_code: 'FR',
  #                farm_number: '01999999',
  #                animal_country_code: 'FR',
  #                animal_id: '3300000005',
  #                exit_date: '2015-02-17',
  #                exit_reason: 'H',
  #                dest_country_code: 'FR',
  #                dest_farm_number: '01000000',
  #                dest_owner_name: 'EKYLIBRE_TEST_DEST'
  #       }
  #
  #       exception = assert_raise(::Tele::Idele::EdnotifError::ParsingError){ @tr.create_cattle_exit args }
  #
  #       assert_equal('9lpBM010', exception.code)
  #
  #
  #     end
  #
  #   end
  #
  #   test 'passing creation cattle new birth on Ednotif' do
  #
  #     authenticated = @tr.authenticate
  #
  #     if authenticated
  #
  #       args = { farm_country_code: 'FR',
  #                farm_number: '01999999',
  #                animal_country_code: 'FR',
  #                animal_id: '3300000006',
  #                sex: 'M',
  #                race_code: '56',
  #                birth_date: '2015-02-18',
  #                work_number: '0001',
  #                cattle_name: 'calypso',
  #                transplant: 'false',
  #                abortion: 'false',
  #                twin: 'false',
  #                birth_condition: '1',
  #                birth_weight: '25',
  #                weighed: 'false',
  #                bust_size: '393',
  #                mother_animal_country_code: 'FR',
  #                mother_animal_id: '3300000004',
  #                mother_race_code: '56',
  #                father_animal_country_code: 'FR',
  #                father_animal_id: '3300000003',
  #                father_race_code: '56',
  #                passport_ask: 'false',
  #                prod_code: nil
  #       }
  #
  #       assert_nothing_raised(::Tele::Idele::EdnotifError::ParsingError) do
  #         status = @tr.create_cattle_new_birth args
  #         assert_equal('validated', status)
  #       end
  #
  #     end
  #
  #   end

  #   test 'raising exception date invalid while creating cattle new birth on Ednotif' do
  #
  #     authenticated = @tr.authenticate
  #
  #     if authenticated
  #
  #       args = { farm_country_code: 'FR',
  #                farm_number: '01999999',
  #                animal_country_code: 'FR',
  #                animal_id: '3300000006',
  #                sex: 'M',
  #                race_code: '56',
  #                birth_date: '2015-12-31', #hacked to raise exception
  #                work_number: '0001',
  #                cattle_name: 'calypso',
  #                transplant: 'false',
  #                abortion: 'false',
  #                twin: 'false',
  #                birth_condition: '1',
  #                birth_weight: '25',
  #                weighed: 'false',
  #                bust_size: '393',
  #                mother_animal_country_code: 'FR',
  #                mother_animal_id: '3300000004',
  #                mother_race_code: '56',
  #                father_animal_country_code: 'FR',
  #                father_animal_id: '3300000003',
  #                father_race_code: '56',
  #                passport_ask: 'false',
  #                prod_code: nil
  #       }
  #
  #       exception = assert_raise(::Tele::Idele::EdnotifError::ParsingError){ @tr.create_cattle_new_birth args }
  #
  #       assert_equal('9IpBI052', exception.code)
  #
  #     end
  #
  #   end

  #   test 'raising exception date invalid while creating cattle new still birth on Ednotif' do
  #
  #     authenticated = @tr.authenticate
  #
  #     if authenticated
  #
  #       args = { farm_country_code: 'FR',
  #                farm_number: '01999999',
  #                sex: 'M',
  #                race_code: '56',
  #                birth_date: '2015-12-31', #hacked to raise exception
  #                cattle_name: 'calypso',
  #                transplant: 'false',
  #                abortion: 'false',
  #                twin: 'false',
  #                birth_condition: '1',
  #                birth_weight: '25',
  #                weighed: 'false',
  #                bust_size: '393',
  #                mother_animal_country_code: 'FR',
  #                mother_animal_id: '3300000004',
  #                mother_race_code: '56',
  #                father_animal_country_code: 'FR',
  #                father_animal_id: '3300000003',
  #                father_race_code: '56'
  #       }
  #
  #       exception = assert_raise(::Tele::Idele::EdnotifError::ParsingError){ @tr.create_cattle_new_stillbirth args }
  #
  #       assert_equal('9IpBI052', exception.code)
  #
  #     end
  #
  #   end

  #   test 'passing creation cattle new stillbirth on Ednotif' do
  #
  #     authenticated = @tr.authenticate
  #
  #     if authenticated
  #
  #       args = { farm_country_code: 'FR',
  #                farm_number: '01999999',
  #                sex: 'M',
  #                race_code: '56',
  #                birth_date: '2015-02-18',
  #                cattle_name: 'calypso',
  #                transplant: 'false',
  #                abortion: 'false',
  #                twin: 'false',
  #                birth_condition: '1',
  #                birth_weight: '25',
  #                weighed: 'false',
  #                bust_size: '393',
  #                mother_animal_country_code: 'FR',
  #                mother_animal_id: '3300000004',
  #                mother_race_code: '56',
  #                father_animal_country_code: 'FR',
  #                father_animal_id: '3300000003',
  #                father_race_code: '56'
  #       }
  #
  #       assert_nothing_raised(::Tele::Idele::EdnotifError::ParsingError) do
  #         status = @tr.create_cattle_new_stillbirth args
  #         assert_equal('validated', status)
  #       end
  #
  #     end
  #
  #   end

  #   test 'passing creation switched animal on Ednotif' do
  #
  #     authenticated = @tr.authenticate
  #
  #     if authenticated
  #
  #       args = { farm_country_code: 'FR',
  #                farm_number: '01999999',
  #                animal_country_code: 'FR',
  #                animal_id: '3300000009',
  #                sex: 'M',
  #                race_code: '56',
  #                birth_date: '2015-02-18',
  #                witness: '0',
  #                work_number: '0003',
  #                cattle_name: 'calypso',
  #                mother_animal_country_code: 'FR',
  #                mother_animal_id: '3300000004',
  #                mother_race_code: '56',
  #                father_animal_country_code: 'FR',
  #                father_animal_id: '3300000003',
  #                father_race_code: '56',
  #                birth_farm_country_code: 'FR',
  #                birth_farm_number: '01000000',
  #                entry_date: '2015-02-18',
  #                entry_reason: 'A',
  #                src_farm_country_code: 'FR',
  #                src_farm_number: '01000001',
  #                src_farm_owner_name: 'EKYLIBRE_TEST',
  #                prod_code: nil,
  #                cattle_categ_code: nil
  #       }
  #
  #       assert_nothing_raised(::Tele::Idele::EdnotifError::ParsingError) do
  #         status = @tr.create_switched_animal args
  #         assert_equal('validated', status)
  #       end
  #
  #     end
  #
  #   end

  #   test 'raising exception invalid data while creating switched animal on Ednotif' do
  #
  #     authenticated = @tr.authenticate
  #
  #     if authenticated
  #
  #       args = { farm_country_code: 'FR',
  #                farm_number: '01999999',
  #                animal_country_code: 'FR',
  #                animal_id: '3300000009',
  #                sex: 'M',
  #                race_code: '56',
  #                birth_date: '2015-02-18',
  #                witness: '0',
  #                work_number: '0003',
  #                cattle_name: 'calypso',
  #                mother_animal_country_code: 'FR',
  #                mother_animal_id: '3300000004',
  #                mother_race_code: '56',
  #                father_animal_country_code: 'FR',
  #                father_animal_id: '3300000003',
  #                father_race_code: '56',
  #                birth_farm_country_code: 'FR',
  #                birth_farm_number: '01000000',
  #                entry_date: '2015-02-18',
  #                entry_reason: 'A',
  #                src_farm_country_code: 'FR',
  #                src_farm_number: '01000001',
  #                src_farm_owner_name: 'EKYLIBRE_TEST',
  #                prod_code: nil,
  #                cattle_categ_code: nil
  #       }
  #
  #       exception = assert_raise(::Tele::Idele::EdnotifError::ParsingError){ @tr.create_switched_animal args }
  #
  #       assert_equal('9IpBI001', exception.code)
  #
  #
  #     end
  #
  #   end

  #   test 'passing creation imported animal notice on Ednotif' do
  #
  #     authenticated = @tr.authenticate
  #
  #     if authenticated
  #
  #       args = { farm_country_code: 'FR',
  #                farm_number: '01999999',
  #                src_animal_country_code: 'FR',
  #                src_animal_id: '3300000009'
  #       }
  #
  #       assert_nothing_raised(::Tele::Idele::EdnotifError::ParsingError) do
  #         status = @tr.create_imported_animal_notice args
  #         assert_equal('validated', status)
  #       end
  #
  #     end
  #
  #   end

  #   test 'raising exception invalid data while creating imported animal notice on Ednotif' do
  #
  #     authenticated = @tr.authenticate
  #
  #     if authenticated
  #
  #       args = { farm_country_code: 'FR',
  #                farm_number: '01999999',
  #                src_animal_country_code: 'FR',
  #                src_animal_id: '3300000009'
  #       }
  #
  #       exception = assert_raise(::Tele::Idele::EdnotifError::ParsingError){ @tr.create_imported_animal_notice args }
  #
  #       assert_equal('9IpBI049', exception.code)
  #
  #
  #     end
  #
  #   end
  #
  #   test 'passing creation imported animal on Ednotif' do
  #
  #     authenticated = @tr.authenticate
  #
  #     if authenticated
  #
  #       args = { farm_country_code: 'FR',
  #                farm_number: '01999999',
  #                animal_country_code: 'FR',
  #                animal_id: '3300000009',
  #                sex: 'M',
  #                race_code: '56',
  #                birth_date: '2015-02-18',
  #                witness: '0',
  #                work_number: '0003',
  #                cattle_name: 'calypso',
  #                mother_animal_country_code: 'FR',
  #                mother_animal_id: '3300000004',
  #                mother_race_code: '56',
  #                father_animal_country_code: 'FR',
  #                father_animal_id: '3300000003',
  #                father_race_code: '56',
  #                birth_farm_country_code: 'YE',
  #                birth_farm_number: '01000000',
  #                src_animal_country_code: 'YE',
  #                src_animal_id: '0000000009',
  #                entry_date: '2015-02-18',
  #                entry_reason: 'A',
  #                src_farm_country_code: 'DE',
  #                src_farm_number: '01000001',
  #                src_farm_owner_name: 'EKYLIBRE_TEST',
  #                prod_code: nil,
  #                cattle_categ_code: nil
  #       }
  #
  #       assert_nothing_raised(::Tele::Idele::EdnotifError::ParsingError) do
  #         status = @tr.create_switched_animal args
  #         assert_equal('validated', status)
  #       end
  #
  #     end
  #
  #   end

  #
  #   test 'passing getting cattle list on Ednotif' do
  #
  #     authenticated = @tr.authenticate
  #
  #     if authenticated
  #
  #       args = { farm_country_code: 'FR',
  #                farm_number: '01999999',
  #                start_date: '2015-01-01',
  #                end_date: '2015-02-18',
  #                stock: 'true'
  #       }
  #
  #       assert_nothing_raised(::Tele::Idele::EdnotifError::ParsingError) do
  #         res = @tr.get_cattle_list args
  #
  #         assert_equal('validated', res[:status])
  #         assert_not_nil(res[:output_hash])
  #       end
  #
  #     end
  #
  #   end

  #
  #
  #   test 'passing getting case feedback on Ednotif' do
  #
  #     authenticated = @tr.authenticate
  #
  #     if authenticated
  #
  #       args = { farm_country_code: 'FR',
  #                farm_number: '01999999',
  #                start_date: '2015-02-01'
  #       }
  #
  #       assert_nothing_raised(::Tele::Idele::EdnotifError::ParsingError) do
  #         res = @tr.get_case_feedback args
  #
  #         assert_equal('validated', res[:status])
  #         assert_not_nil(res[:output_hash])
  #       end
  #
  #     end
  #
  #   end

  #
  #   test 'passing getting animal case on Ednotif' do
  #
  #     authenticated = @tr.authenticate
  #
  #     if authenticated
  #
  #       args = { farm_country_code: 'FR',
  #                farm_number: '01999999',
  #                animal_country_code: 'FR',
  #                animal_id: '3300000004'
  #       }
  #
  #       assert_nothing_raised(::Tele::Idele::EdnotifError::ParsingError) do
  #         res = @tr.get_animal_case args
  #
  #         assert_equal('validated', res[:status])
  #         assert_not_nil(res[:output_hash])
  #       end
  #
  #     end
  #
  #   end
  #
  #   test 'passing getting presumed exit on Ednotif' do
  #
  #     authenticated = @tr.authenticate
  #
  #     if authenticated
  #
  #       args = { farm_country_code: 'FR',
  #                farm_number: '01999999'
  #       }
  #
  #       assert_nothing_raised(::Tele::Idele::EdnotifError::ParsingError) do
  #         res = @tr.get_presumed_exit args
  #
  #         assert_equal('validated', res[:status])
  #         assert_not_nil(res[:output_hash])
  #       end
  #
  #     end
  #
  #   end

  #   test 'passing create commande boucles on Ednotif' do
  #
  #     authenticated = @tr.authenticate
  #
  #     if authenticated
  #
  #       args = { farm_country_code: 'FR',
  #                farm_number: '01999999',
  #                animal_country_code: 'FR',
  #                animal_id: '3300000004',
  #                boucle_conventionnelle: 'true',
  #                boucle_travail: '',
  #                boucle_electronique: nil,
  #                cause_remplacement: 'C'
  #       }
  #
  #       #TODO !
  #
  #       assert_nothing_raised(::Tele::Idele::EdnotifError::ParsingError) do
  #         status = @tr.create_commande_boucles args
  #
  #         assert_equal('validated', status)
  #       end
  #
  #     end
  #
  #   end

  #   test 'passing create rebouclage on Ednotif' do
  #
  #     authenticated = @tr.authenticate
  #
  #     if authenticated
  #
  #       args = { farm_country_code: 'FR',
  #                farm_number: '01999999',
  #                animal_country_code: 'FR',
  #                animal_id: '3300000004',
  #                boucle_conventionnelle: 'true',
  #                boucle_travail: '',
  #                boucle_electronique: nil,
  #                cause_remplacement: 'C'
  #       }
  #
  #       assert_nothing_raised(::Tele::Idele::EdnotifError::ParsingError) do
  #         status = @tr.create_rebouclage args
  #
  #         assert_equal('validated', status)
  #       end
  #
  #     end
  #
  #   end
end
